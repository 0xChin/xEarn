// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';
import {IWETH9} from 'interfaces/tokens/IWETH9.sol';
import {IERC4626} from 'interfaces/tokens/IERC4626.sol';
import {ISwapRouter} from 'interfaces/peripherals/ISwapRouter.sol';
import {ICurveCryptoSwap} from 'interfaces/peripherals/ICurveCryptoSwap.sol';

import {TransferHelper} from 'libraries/TransferHelper.sol';
import {SwapHelper} from 'libraries/SwapHelper.sol';
import {CurveHelper} from 'libraries/CurveHelper.sol';
import {WETH9Helper} from 'libraries/WETH9Helper.sol';

contract VaultManager {
  IWETH9 public immutable WETH;
  ISwapRouter public immutable SWAP_ROUTER;

  constructor(address _weth9, address _swapRouter) {
    WETH = IWETH9(_weth9);
    SWAP_ROUTER = ISwapRouter(_swapRouter);
  }

  function deposit(uint256 _amount, address _token, address _vault, uint24 _poolFee) external returns (uint256 _shares) {
    WETH9Helper.pullEthFromSender(_amount, address(WETH));
    uint256 _amountOut = SwapHelper.swapEthForToken(_token, _amount, _poolFee, address(WETH), address(SWAP_ROUTER));

    IERC20(_token).approve(_vault, _amountOut);
    _shares = IERC4626(_vault).deposit();
  }

  function deposit(uint256 _amount, address _token, address _pool, address _vault) external returns (uint256 _shares) {
    WETH9Helper.pullEthFromSender(_amount, address(WETH));
    uint256 _amountOut = CurveHelper.addCurveLiquidity(_pool, _token, address(WETH), _amount);

    IERC20(_token).approve(_vault, _amountOut);
    _shares = IERC4626(_vault).deposit();
  }
}
