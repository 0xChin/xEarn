// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {Ownable} from 'openzeppelin-contracts/access/Ownable.sol';

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

contract VaultManager is Ownable, IXReceiver {
  address public immutable WETH_ADDRESS;
  address public immutable SWAP_ROUTER_ADDRESS;

  IWETH9 public immutable WETH;
  ISwapRouter public immutable SWAP_ROUTER;

  mapping(uint32 => mapping(address => bool)) public originsAllowlist;

  error WrongAmount();
  error WrongAsset();
  error WrongOrigin();

  constructor(address _weth9, address _swapRouter) {
    WETH_ADDRESS = _weth9;
    SWAP_ROUTER_ADDRESS = _swapRouter;

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
    if (_amount == 0) revert WrongAmount();
    if (_asset != WETH_ADDRESS) revert WrongAsset();
    if (!originsAllowlist[_origin][_originSender]) revert WrongOrigin();
  }

  function deposit(uint256 _amount, address _token, address _vault, uint24 _poolFee) external returns (uint256 _shares) {
    WETH9Helper.pullEthFromSender(_amount, WETH_ADDRESS);
    uint256 _amountOut = SwapHelper.swapEthForToken(_token, _amount, _poolFee, WETH_ADDRESS, SWAP_ROUTER_ADDRESS);

    IERC20(_token).approve(_vault, _amountOut);
    _shares = IERC4626(_vault).deposit();
  }

  function deposit(uint256 _amount, address _token, address _vault, address _pool) external returns (uint256 _shares) {
    WETH9Helper.pullEthFromSender(_amount, WETH_ADDRESS);
    uint256 _amountOut = CurveHelper.addCurveLiquidity(_pool, _token, WETH_ADDRESS, _amount);

    IERC20(_token).approve(_vault, _amountOut);
    _shares = IERC4626(_vault).deposit();
  }

  function addToAllowlist(uint32 origin, address _address) external onlyOwner {
    originsAllowlist[origin][_address] = true;
  }

  function removeFromAllowlist(uint32 origin, address _address) external onlyOwner {
    delete originsAllowlist[origin][_address];
  }
}
