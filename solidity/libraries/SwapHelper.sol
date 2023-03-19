// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {TransferHelper} from 'libraries/TransferHelper.sol';
import {ISwapRouter} from 'interfaces/peripherals/ISwapRouter.sol';

library SwapHelper {
  function swapEthForToken(
    address _token,
    uint256 _amount,
    uint24 _poolFee,
    address _weth,
    address _swapRouter
  ) internal returns (uint256 _amountOut) {
    TransferHelper.safeApprove(address(_weth), _swapRouter, _amount);

    ISwapRouter.ExactInputSingleParams memory _params = ISwapRouter.ExactInputSingleParams({
      tokenIn: address(_weth),
      tokenOut: _token,
      fee: _poolFee,
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: _amount,
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0
    });

    _amountOut = ISwapRouter(_swapRouter).exactInputSingle(_params);
  }
}
