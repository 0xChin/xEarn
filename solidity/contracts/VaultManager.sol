// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {Ownable} from 'openzeppelin-contracts/access/Ownable.sol';

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

contract VaultManager is Ownable, IXReceiver {
  uint32 public immutable MAIN_CHAIN;

  IWETH9 public immutable weth;
  ISwapRouter public immutable swapRouter;
  IConnext public immutable connext;

  mapping(address => mapping(address => uint256)) public shares;

  error WrongAmount();
  error WrongAsset();
  error UnauthorizedCaller();

  enum OperationType {
    DepositToken,
    DepositCurveLP,
    WithdrawToken,
    WithdrawCurveLP
  }

  constructor(address _weth9, address _swapRouter, address _connext, uint32 _mainChain) {
    MAIN_CHAIN = _mainChain;

    weth = IWETH9(_weth9);
    swapRouter = ISwapRouter(_swapRouter);
    connext = IConnext(_connext);

    weth.approve(_weth9, type(uint256).max);
  }

  /// @notice Key function of the contract
  /// @dev Receives connext calls, enables interoperability
  /// @param _amount Amount of asset received
  /// @param _asset Address of token received
  /// @param _callData Calldata
  function xReceive(
    bytes32,
    uint256 _amount,
    address _asset,
    address,
    uint32,
    bytes memory _callData
  ) external returns (bytes memory) {
    /// @param _msgSender End user that made the call
    /// @param _vault Vault address
    /// @param _data Either pool fee or a Curve pool address
    /// @param _relayerFee Relayer fee used if withdrawing
    /// @param _operationType Type of operation: Deposit/Withdrawal and type of asset: Token/Curve LP
    (address _msgSender, address _vault, uint256 _relayerFee, bytes32 _data, OperationType _operationType) =
      abi.decode(_callData, (address, address, uint256, bytes32, OperationType));

    if (_operationType == OperationType.DepositToken) {
      if (_asset != address(weth)) revert WrongAsset();
      if (_amount == 0) revert WrongAmount();

      uint24 _poolFee = uint24(uint256(_data));

      _deposit(_amount, _vault, _poolFee, _msgSender);
    } else if (_operationType == OperationType.DepositCurveLP) {
      if (_asset != address(weth)) revert WrongAsset();
      if (_amount == 0) revert WrongAmount();

      address _pool = address(uint160(uint256(_data)));

      _deposit(_amount, _vault, _pool, _msgSender);
    } else if (_operationType == OperationType.WithdrawToken) {
      uint24 _poolFee = uint24(uint256(_data));

      _withdraw(_vault, _poolFee, _msgSender, _relayerFee);
    } else {
      address _pool = address(uint160(uint256(_data)));

      _withdraw(_vault, _pool, _msgSender, _relayerFee);
    }

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

    uint256 _amountOut = SwapHelper.swapEthForToken(_token, _amount, _poolFee, address(weth), address(swapRouter));

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

    uint256 _amountOut = CurveHelper.addLiquidity(_pool, _token, address(weth), _amount);

    IERC20(_token).approve(_vault, _amountOut);
    _shares = vault.deposit();

    shares[_msgSender][_vault] += _shares;
  }

  function _withdraw(
    address _vault,
    uint24 _poolFee,
    address _msgSender,
    uint256 _relayerFee
  ) internal returns (uint256 _shares) {
    IERC4626 vault = IERC4626(_vault);
    address _token = vault.token();

    _shares = vault.withdraw(shares[_msgSender][_vault]);

    uint256 _amountOut =
      (SwapHelper.swapTokenForEth(_token, _shares, _poolFee, address(weth), address(swapRouter)) - _relayerFee);

    weth.withdraw(_relayerFee);
    weth.transfer(address(connext), _amountOut);
    connext.xcall{value: _relayerFee}(MAIN_CHAIN, _msgSender, address(weth), _msgSender, _amountOut, 10_000, bytes(''));

    delete shares[_msgSender][_vault];
  }

  function _withdraw(
    address _vault,
    address _pool,
    address _msgSender,
    uint256 _relayerFee
  ) internal returns (uint256 _shares) {
    IERC4626 vault = IERC4626(_vault);

    _shares = vault.withdraw(shares[_msgSender][_vault]);

    uint256 _amountOut = (CurveHelper.removeLiquidity(_pool, address(weth), _shares) - _relayerFee);

    weth.withdraw(_relayerFee);
    weth.transfer(address(connext), _amountOut);
    connext.xcall{value: _relayerFee}(MAIN_CHAIN, _msgSender, address(weth), _msgSender, _amountOut, 10_000, bytes(''));

    delete shares[_msgSender][_vault];
  }

  receive() external payable {
    require(msg.sender == address(weth));
  }
}
