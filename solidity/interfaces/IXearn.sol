// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IWETH9} from 'interfaces/tokens/IWETH9.sol';
import {ISwapRouter} from 'interfaces/peripherals/ISwapRouter.sol';
import {IConnext} from 'connext/IConnext.sol';

interface IXearn {
  // ENUMS

  struct DepositArgs {
    address target; // Address of the destination contract
    address vault; // Address of the Yearn vault
    address curvePool; // Address of the Curve pool (if applies)
    uint32 destinationDomain; // Address of the destination chain/rollup
    uint24 poolFee; // Fee to pay in Uniswap swap (if applies)
    uint256 amount; // Amount to send
    uint256 relayerFee; // Relayer fee to pay in xcall
  }

  struct WithdrawArgs {
    address target; // Address of the destination contract
    address vault; // Address of the Yearn vault
    address curvePool; // Address of the Curve pool (if applies)
    uint32 destinationDomain; // Address of the destination chain/rollup
    uint24 poolFee; // Fee to pay in Uniswap swap (if applies)
    uint256 amount; // Amount to send (zero when withdrawing)
    uint256 relayerFee; // Relayer fee to pay in xcall
    uint256 xRelayerFee; // Relayer fee to pay from destination domain to source domain
  }

  // STATE VARIABLES

  function MAIN_CHAIN() external view returns (uint32 _mainChain);

  function weth() external view returns (IWETH9 _weth);

  function swapRouter() external view returns (ISwapRouter _swapRouter);

  function connext() external view returns (IConnext _connext);

  function shares(address _owner, address _vault) external view returns (uint256 _amount);

  // ERRORS

  error WrongAmount();
  error WrongAsset();
  error UnauthorizedCaller();
  error OnlyWeth();
}
