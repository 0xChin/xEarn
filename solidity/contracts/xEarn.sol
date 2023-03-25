// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IConnext} from 'connext/IConnext.sol';
import {VaultManager} from 'contracts/VaultManager.sol';
import {IWETH9} from 'interfaces/tokens/IWETH9.sol';

contract XEarn {
  IConnext public immutable connext;
  IWETH9 public immutable weth;

  struct DepositArgs {
    address target;
    address vault;
    address curvePool;
    uint32 destinationDomain;
    uint24 poolFee;
    uint256 amount;
    uint256 relayerFee;
  }

  struct WithdrawArgs {
    address target;
    address vault;
    address curvePool;
    uint32 destinationDomain;
    uint24 poolFee;
    uint256 amount;
    uint256 relayerFee;
    uint256 xRelayerFee;
  }

  constructor(address _weth9, address _connext) {
    connext = IConnext(_connext);
    weth = IWETH9(_weth9);
  }

  function deposit(DepositArgs memory args) public payable {
    weth.transferFrom(msg.sender, address(this), args.amount);
    weth.approve(address(connext), args.amount);

    bytes memory _callData;
    if (args.curvePool == address(0)) {
      _callData = abi.encode(msg.sender, args.vault, 0, args.poolFee, VaultManager.OperationType.DepositToken);
    } else {
      _callData = abi.encode(msg.sender, args.vault, 0, args.curvePool, VaultManager.OperationType.DepositCurveLP);
    }

    connext.xcall{value: args.relayerFee}(
      args.destinationDomain, args.target, address(weth), msg.sender, args.amount, 500, _callData
    );
  }

  function withdraw(WithdrawArgs memory args) public payable {
    bytes memory _callData;
    if (args.curvePool == address(0)) {
      _callData =
        abi.encode(msg.sender, args.vault, args.xRelayerFee, args.poolFee, VaultManager.OperationType.WithdrawToken);
    } else {
      _callData =
        abi.encode(msg.sender, args.vault, args.xRelayerFee, args.curvePool, VaultManager.OperationType.WithdrawCurveLP);
    }

    connext.xcall{value: args.relayerFee}(
      args.destinationDomain, args.target, address(weth), msg.sender, args.amount, 500, _callData
    );
  }

  function multiDeposit(DepositArgs[] memory args) external payable {
    for (uint256 i = 0; i < args.length; i++) {
      deposit(args[i]);
    }
  }

  function multiWithdraw(WithdrawArgs[] memory args) external payable {
    for (uint256 i = 0; i < args.length; i++) {
      withdraw(args[i]);
    }
  }
}
