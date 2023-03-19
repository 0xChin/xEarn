// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {TransferHelper} from 'libraries/TransferHelper.sol';
import {ICurveCryptoSwap} from 'interfaces/peripherals/ICurveCryptoSwap.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';

library CurveHelper {
  function addCurveLiquidity(
    address _pool,
    address _poolToken,
    address _token,
    uint256 _amount
  ) internal returns (uint256 _amountOut) {
    TransferHelper.safeApprove(address(_token), _pool, _amount);

    uint256[3] memory _amounts = [0, 0, _amount];
    ICurveCryptoSwap(_pool).add_liquidity(_amounts, 0);

    _amountOut = IERC20(_poolToken).balanceOf(address(this));
  }
}
