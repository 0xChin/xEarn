// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';
import {IWETH9} from 'interfaces/tokens/IWETH9.sol';
import {IERC4626} from 'interfaces/tokens/IERC4626.sol';
import {ISwapRouter} from 'interfaces/peripherals/ISwapRouter.sol';
import {ICurveCryptoSwap} from 'interfaces/peripherals/ICurveCryptoSwap.sol';
import {TransferHelper} from 'libraries/TransferHelper.sol';

contract VaultManager {
  IWETH9 public immutable WETH9;
  ISwapRouter public immutable SWAP_ROUTER;

  constructor(address _weth9, address _swapRouter) {
    WETH9 = IWETH9(_weth9);
    SWAP_ROUTER = ISwapRouter(_swapRouter);
  }

  function deposit(uint256 _amount, address _token, address _vault, uint24 _poolFee) external returns (uint256 _shares) {
    _pullEth(_amount);
    uint256 _amountOut = _swapForEth(_token, _amount, _poolFee);

    IERC20(_token).approve(_vault, _amountOut);
    _shares = IERC4626(_vault).deposit();
  }

  function deposit(uint256 _amount, address _token, address _pool, address _vault) external returns (uint256 _shares) {
    _pullEth(_amount);
    uint256 _amountOut = _addCurveLiquidity(_pool, _token, _amount);

    IERC20(_token).approve(_vault, _amountOut);
    _shares = IERC4626(_vault).deposit();
  }

  function _swapForEth(address _token, uint256 _amount, uint24 _poolFee) internal returns (uint256 _amountOut) {
    TransferHelper.safeApprove(address(WETH9), address(SWAP_ROUTER), _amount);

    ISwapRouter.ExactInputSingleParams memory _params = ISwapRouter.ExactInputSingleParams({
      tokenIn: address(WETH9),
      tokenOut: _token,
      fee: _poolFee,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: _amount,
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0
    });

    _amountOut = SWAP_ROUTER.exactInputSingle(_params);
  }

  function _addCurveLiquidity(address _pool, address _token, uint256 _amount) internal returns (uint256 _amountOut) {
    TransferHelper.safeApprove(address(WETH9), _pool, _amount);

    uint256[3] memory _amounts = [0, 0, _amount];
    ICurveCryptoSwap(_pool).add_liquidity(_amounts, 0);

    _amountOut = IERC20(_token).balanceOf(address(this));
  }

  function _pullEth(uint256 _amount) internal {
    WETH9.transferFrom(msg.sender, address(this), _amount);
  }
}
