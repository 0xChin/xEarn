// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {TransferHelper} from 'libraries/TransferHelper.sol';
import {ICurveCryptoSwap} from 'interfaces/peripherals/ICurveCryptoSwap.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';

library CurveHelper {
  /// @notice Adds liquidity to a Curve pool
  /// @dev It's currently compatible only with Arbitrum's Tricrypto pool
  /// @param _pool The pool to which liquidity is added
  /// @param _lpToken LP token received after providing liquidity
  /// @param _token Token to provide liquidity with, in this case, always WETH
  /// @param _amount Amount of tokens to send
  /// @return _amountOut LP tokens received after adding liquidity
  function addLiquidity(
    address _pool,
    address _lpToken,
    address _token,
    uint256 _amount
  ) internal returns (uint256 _amountOut) {
    TransferHelper.safeApprove(_token, _pool, _amount);

    uint256[3] memory _amounts = [0, 0, _amount]; // Sending only 1 token
    ICurveCryptoSwap(_pool).add_liquidity(_amounts, 0); // Min mint amount set to 0

    _amountOut = IERC20(_lpToken).balanceOf(address(this));
  }

  /// @notice Removes liquidity from a Curve pool
  /// @dev It's currently compatible only with Arbitrum's Tricrypto pool
  /// @param _pool The pool from which liquidity is removed
  /// @param _token Token to receive after removing liquidity
  /// @param _amount Amount of tokens to remove
  /// @return _amountOut Tokens withdrawn
  function removeLiquidity(address _pool, address _token, uint256 _amount) internal returns (uint256 _amountOut) {
    uint256 _wethIndex = 2;

    ICurveCryptoSwap(_pool).remove_liquidity_one_coin(_amount, _wethIndex, 0); // Min withdraw amount set to 0

    _amountOut = IERC20(_token).balanceOf(address(this));
  }
}
