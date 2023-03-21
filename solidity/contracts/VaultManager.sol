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

import {TransferHelper} from 'libraries/TransferHelper.sol';
import {SwapHelper} from 'libraries/SwapHelper.sol';
import {CurveHelper} from 'libraries/CurveHelper.sol';
import {WETH9Helper} from 'libraries/WETH9Helper.sol';

contract VaultManager is Ownable, IXReceiver, OriginsAllowlist {
  address public immutable WETH_ADDRESS;
  address public immutable SWAP_ROUTER_ADDRESS;
  address public immutable CONNEXT;

  IWETH9 public immutable WETH;
  ISwapRouter public immutable SWAP_ROUTER;

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

  constructor(address _weth9, address _swapRouter, address _connext) {
    WETH_ADDRESS = _weth9;
    SWAP_ROUTER_ADDRESS = _swapRouter;
    CONNEXT = _connext;

    WETH = IWETH9(_weth9);
    SWAP_ROUTER = ISwapRouter(_swapRouter);
  }

  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external returns (bytes memory) {
    if (msg.sender != CONNEXT) revert NotConnextRouter();
    if (!allowlist[_origin][_originSender]) revert WrongOrigin();

    (address _msgSender, address _token, address _vault, bytes32 _canChange, OperationType _operationType) =
      abi.decode(_callData, (address, address, address, bytes32, OperationType));

    if (_operationType == OperationType.DepositToken) {
      if (_asset != WETH_ADDRESS) revert WrongAsset();
      if (_amount == 0) revert WrongAmount();

      WETH9Helper.pullEthFromSender(_amount, WETH_ADDRESS);
      _deposit(_amount, _token, _vault, uint24(uint256(_canChange)), _msgSender);
    } else if (_operationType == OperationType.DepositCurveLP) {
      if (_asset != WETH_ADDRESS) revert WrongAsset();
      if (_amount == 0) revert WrongAmount();

      WETH9Helper.pullEthFromSender(_amount, WETH_ADDRESS);
      _deposit(_amount, _token, _vault, address(uint160(uint256(_canChange))), _msgSender);
    } else if (_operationType == OperationType.WithdrawToken) {
      _withdraw(_token, _vault, uint24(uint256(_canChange)), _msgSender);
    } else {
      _withdraw(_vault, address(uint160(uint256(_canChange))), _msgSender);
    }

    emit XReceived(_transferId);
  }

  function _deposit(
    uint256 _amount,
    address _token,
    address _vault,
    uint24 _poolFee,
    address _msgSender
  ) internal returns (uint256 _shares) {
    uint256 _amountOut = SwapHelper.swapEthForToken(_token, _amount, _poolFee, WETH_ADDRESS, SWAP_ROUTER_ADDRESS);

    IERC20(_token).approve(_vault, _amountOut);
    _shares = IERC4626(_vault).deposit();

    shares[_msgSender][_vault] += _shares;
  }

  function _deposit(
    uint256 _amount,
    address _token,
    address _vault,
    address _pool,
    address _msgSender
  ) internal returns (uint256 _shares) {
    uint256 _amountOut = CurveHelper.addLiquidity(_pool, _token, WETH_ADDRESS, _amount);

    IERC20(_token).approve(_vault, _amountOut);
    _shares = IERC4626(_vault).deposit();

    shares[_msgSender][_vault] += _shares;
  }

  function _withdraw(
    address _token,
    address _vault,
    uint24 _poolFee,
    address _msgSender
  ) internal returns (uint256 _shares) {
    _shares = IERC4626(_vault).withdraw(shares[_msgSender][_vault]);

    uint256 _amountOut = SwapHelper.swapTokenForEth(_token, _shares, _poolFee, WETH_ADDRESS, SWAP_ROUTER_ADDRESS);
    WETH.transfer(_msgSender, _amountOut);

    delete shares[_msgSender][_vault];
  }

  function _withdraw(address _vault, address _pool, address _msgSender) internal returns (uint256 _shares) {
    _shares = IERC4626(_vault).withdraw(shares[_msgSender][_vault]);

    uint256 _amountOut = CurveHelper.removeLiquidity(_pool, WETH_ADDRESS, _shares);

    WETH.transfer(_msgSender, _amountOut);

    delete shares[_msgSender][_vault];
  }
}
