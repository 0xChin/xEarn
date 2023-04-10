// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IWETH9} from 'interfaces/tokens/IWETH9.sol';
import {ISwapRouter} from 'interfaces/peripherals/ISwapRouter.sol';
import {IConnext} from 'connext/IConnext.sol';

interface IVaultManager {
  // ENUMS

  enum OperationType {
    DepositToken, // e.g. USDT
    DepositCurveLP, // e.g. Tricrypto LP
    WithdrawToken, // e.g. USDT
    WithdrawCurveLP // e.g. Tricrypto LP
  }

  // STATE VARIABLES

  function weth() external view returns (IWETH9 _weth);

  function connext() external view returns (IConnext _connext);

  // ERRORS

  error WrongAmount();
  error WrongAsset();
  error UnauthorizedCaller();
  error OnlyWeth();
}
