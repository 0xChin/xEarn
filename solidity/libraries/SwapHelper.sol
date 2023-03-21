// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {TransferHelper} from 'libraries/TransferHelper.sol';
import {ISwapRouter} from 'interfaces/peripherals/ISwapRouter.sol';

library SwapHelper {
  /// @notice Swaps WETH for any token
  /// @param _token Token to get
  /// @param _amount Amount of ETH to swap
  /// @param _poolFee Pool fee
  /// @param _weth WETH address
  /// @param _swapRouter Swap Router address
  /// @return _amountOut Tokens received after swap
  function swapEthForToken(
    address _token,
    uint256 _amount,
    uint24 _poolFee,
    address _weth,
    address _swapRouter
  ) internal returns (uint256 _amountOut) {
    TransferHelper.safeApprove(address(_weth), _swapRouter, _amount);

    ISwapRouter.ExactInputSingleParams memory _params = ISwapRouter.ExactInputSingleParams({
      tokenIn: _weth,
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

  /// @notice Swaps any token for WETH\
  /// @param _token Token to send
  /// @param _amount Amount to swap
  /// @param _poolFee Pool fee
  /// @param _weth WETH address
  /// @param _swapRouter Swap Router address
  /// @return _amountOut WETH received after swap
  function swapTokenForEth(
    address _token,
    uint256 _amount,
    uint24 _poolFee,
    address _weth,
    address _swapRouter
  ) internal returns (uint256 _amountOut) {
    TransferHelper.safeApprove(address(_token), _swapRouter, _amount);

    ISwapRouter.ExactInputSingleParams memory _params = ISwapRouter.ExactInputSingleParams({
      tokenIn: _token,
      tokenOut: _weth,
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
