// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {Ownable} from 'openzeppelin-contracts/access/Ownable.sol';
import {OriginsAllowlist} from 'contracts/OriginsAllowlist.sol';

import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';
import {IWETH9} from 'interfaces/tokens/IWETH9.sol';
import {IERC4626} from 'interfaces/tokens/IERC4626.sol';
import {ISwapRouter} from 'interfaces/peripherals/ISwapRouter.sol';
import {ICurveCryptoSwap} from 'interfaces/peripherals/ICurveCryptoSwap.sol';
import {IXReceiver} from 'connext/IXReceiver.sol';
import {IConnext} from 'connext/IConnext.sol';

import {TransferHelper} from 'libraries/TransferHelper.sol';
import {SwapHelper} from 'libraries/SwapHelper.sol';
import {CurveHelper} from 'libraries/CurveHelper.sol';
import {WETH9Helper} from 'libraries/WETH9Helper.sol';

contract VaultManager is Ownable, IXReceiver, OriginsAllowlist {
  uint32 public immutable MAIN_CHAIN;

  address public immutable WETH_ADDRESS;
  address public immutable SWAP_ROUTER_ADDRESS;
  address public immutable CONNEXT_ADDRESS;

  IWETH9 public immutable WETH;
  ISwapRouter public immutable SWAP_ROUTER;
  IConnext public immutable CONNEXT;

  mapping(address => mapping(address => uint256)) public shares;

  event XReceived(bytes32 indexed _transferId);

  error WrongAmount();
  error WrongAsset();
  error WrongOrigin();
  error NotConnextRouter();

  enum OperationType {
    DepositToken,
    DepositCurveLP,
    WithdrawToken,
    WithdrawCurveLP
  }

  constructor(address _weth9, address _swapRouter, address _connext, uint32 _mainChain) {
    MAIN_CHAIN = _mainChain;

    WETH_ADDRESS = _weth9;
    SWAP_ROUTER_ADDRESS = _swapRouter;
    CONNEXT_ADDRESS = _connext;

    WETH = IWETH9(_weth9);
    SWAP_ROUTER = ISwapRouter(_swapRouter);
    CONNEXT = IConnext(_connext);

    WETH.approve(_weth9, type(uint256).max);
  }

  /// @notice Key function of the contract
  /// @dev Receives connext calls, enables interoperability
  /// @param _transferId Transfer ID
  /// @param _amount Amount of asset received
  /// @param _asset Address of token received
  /// @param _originSender Address of caller in the other origin
  /// @param _origin Domain ID AKA chain/rollup identifier
  /// @param _callData Calldata
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external returns (bytes memory) {
    if (msg.sender != CONNEXT_ADDRESS) revert NotConnextRouter();
    if (!allowlist[_origin][_originSender]) revert WrongOrigin();

    /// @param _msgSender End user that made the call
    /// @param _vault Vault address
    /// @param _data Either pool fee or a Curve pool address
    /// @param _operationType Type of operation: Deposit/Withdrawal and type of asset: Token/Curve LP
    (address _msgSender, address _vault, bytes32 _data, uint256 _relayerFee, OperationType _operationType) =
      abi.decode(_callData, (address, address, bytes32, uint256, OperationType));

    if (_operationType == OperationType.DepositToken) {
      if (_asset != WETH_ADDRESS) revert WrongAsset();
      if (_amount == 0) revert WrongAmount();

      uint24 _poolFee = uint24(uint256(_data));

      _deposit(_amount, _vault, _poolFee, _msgSender);
    } else if (_operationType == OperationType.DepositCurveLP) {
      if (_asset != WETH_ADDRESS) revert WrongAsset();
      if (_amount == 0) revert WrongAmount();

      address _pool = address(uint160(uint256(_data)));

      _deposit(_amount, _vault, _pool, _msgSender);
    } else if (_operationType == OperationType.WithdrawToken) {
      uint24 _poolFee = uint24(uint256(_data));

      _withdraw(_vault, _poolFee, _msgSender, _relayerFee, _origin);
    } else {
      address _pool = address(uint160(uint256(_data)));

      _withdraw(_vault, _pool, _msgSender, _relayerFee, _origin);
    }

    emit XReceived(_transferId);

    return abi.encode('');
  }

  function _deposit(
    uint256 _amount,
    address _vault,
    uint24 _poolFee,
    address _msgSender
  ) internal returns (uint256 _shares) {
    IERC4626 vault = IERC4626(_vault);
    address _token = vault.token();

    uint256 _amountOut = SwapHelper.swapEthForToken(_token, _amount, _poolFee, WETH_ADDRESS, SWAP_ROUTER_ADDRESS);

    IERC20(_token).approve(_vault, _amountOut);
    _shares = vault.deposit();

    shares[_msgSender][_vault] += _shares;
  }

  function _deposit(
    uint256 _amount,
    address _vault,
    address _pool,
    address _msgSender
  ) internal returns (uint256 _shares) {
    IERC4626 vault = IERC4626(_vault);
    address _token = vault.token();

    uint256 _amountOut = CurveHelper.addLiquidity(_pool, _token, WETH_ADDRESS, _amount);

    IERC20(_token).approve(_vault, _amountOut);
    _shares = vault.deposit();

    shares[_msgSender][_vault] += _shares;
  }

  function _withdraw(
    address _vault,
    uint24 _poolFee,
    address _msgSender,
    uint256 _relayerFee,
    uint32 _destinationDomain
  ) internal returns (uint256 _shares) {
    IERC4626 vault = IERC4626(_vault);
    address _token = vault.token();

    _shares = vault.withdraw(shares[_msgSender][_vault]);

    uint256 _amountOut =
      (SwapHelper.swapTokenForEth(_token, _shares, _poolFee, WETH_ADDRESS, SWAP_ROUTER_ADDRESS) - _relayerFee);

    WETH.withdraw(_relayerFee);
    WETH.transfer(CONNEXT_ADDRESS, _amountOut);

    CONNEXT.xcall{value: _relayerFee}(
      _destinationDomain, _msgSender, WETH_ADDRESS, _msgSender, _amountOut, 10_000, bytes('')
    );

    delete shares[_msgSender][_vault];
  }

  function _withdraw(
    address _vault,
    address _pool,
    address _msgSender,
    uint256 _relayerFee,
    uint32 _destinationDomain
  ) internal returns (uint256 _shares) {
    IERC4626 vault = IERC4626(_vault);

    _shares = vault.withdraw(shares[_msgSender][_vault]);

    uint256 _amountOut = (CurveHelper.removeLiquidity(_pool, WETH_ADDRESS, _shares) - _relayerFee);

    WETH.withdraw(_relayerFee);
    WETH.transfer(CONNEXT_ADDRESS, _amountOut);

    CONNEXT.xcall{value: _relayerFee}(
      _destinationDomain, _msgSender, WETH_ADDRESS, _msgSender, _amountOut, 10_000, bytes('')
    );

    delete shares[_msgSender][_vault];
  }

  receive() external payable {
    require(msg.sender == WETH_ADDRESS);
  }
}
