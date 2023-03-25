// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Script} from 'forge-std/Script.sol';
import {VaultManager} from 'contracts/VaultManager.sol';
import {XEarn} from 'contracts/xEarn.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';

contract Deposit is Script {
  function run() external {
    vm.startBroadcast();

    address _weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address _xEarn = 0xed6229CD962413CbcF07C8f9DD8D30607157Fff7;

    IERC20(_weth).approve(_xEarn, type(uint256).max);

    XEarn.DepositArgs memory _depositArgsOptimism = XEarn.DepositArgs({
      target: 0x30bb5A1858D1CfE22AF5E028F15dD8450E76FDc3,
      destinationDomain: 1_869_640_809,
      amount: 0.0001 ether,
      relayerFee: 0.8 ether,
      vault: 0xFaee21D0f0Af88EE72BB6d68E54a90E6EC2616de,
      poolFee: uint24(3000),
      curvePool: address(0)
    });

    XEarn.DepositArgs memory _depositArgsArbitrum = XEarn.DepositArgs({
      target: 0x305c0C5001f40D8fa21740d1D135Cdbb7Fd97C53,
      destinationDomain: 1_634_886_255,
      amount: 0.0001 ether,
      relayerFee: 0.8 ether,
      vault: 0x239e14A19DFF93a17339DCC444f74406C17f8E67,
      poolFee: 0,
      curvePool: 0x960ea3e3C7FB317332d990873d354E18d7645590
    });

    XEarn.DepositArgs[] memory args = new XEarn.DepositArgs[](2);
    args[0] = _depositArgsOptimism;
    args[1] = _depositArgsArbitrum;

    XEarn(_xEarn).multiDeposit{value: _depositArgsOptimism.relayerFee + _depositArgsArbitrum.relayerFee}(args);
    vm.stopBroadcast();
  }
}

contract Withdraw is Script {
  function run() external {
    vm.startBroadcast();

    address _xEarn = 0xed6229CD962413CbcF07C8f9DD8D30607157Fff7;

    XEarn.WithdrawArgs memory _withdrawArgsOptimism = XEarn.WithdrawArgs({
      target: 0x30bb5A1858D1CfE22AF5E028F15dD8450E76FDc3,
      destinationDomain: 1_869_640_809,
      amount: 0,
      relayerFee: 0.8 ether,
      xRelayerFee: 0.00004 ether,
      vault: 0xFaee21D0f0Af88EE72BB6d68E54a90E6EC2616de,
      poolFee: uint24(3000),
      curvePool: address(0)
    });

    XEarn.WithdrawArgs memory _withdrawArgsArbitrum = XEarn.WithdrawArgs({
      target: 0x305c0C5001f40D8fa21740d1D135Cdbb7Fd97C53,
      destinationDomain: 1_634_886_255,
      amount: 0,
      relayerFee: 0.8 ether,
      xRelayerFee: 0.00004 ether,
      vault: 0x239e14A19DFF93a17339DCC444f74406C17f8E67,
      poolFee: 0,
      curvePool: 0x960ea3e3C7FB317332d990873d354E18d7645590
    });

    XEarn.WithdrawArgs[] memory args = new XEarn.WithdrawArgs[](2);
    args[0] = _withdrawArgsOptimism;
    args[1] = _withdrawArgsArbitrum;

    XEarn(_xEarn).multiWithdraw{value: _withdrawArgsOptimism.relayerFee + _withdrawArgsArbitrum.relayerFee}(args);
    vm.stopBroadcast();
  }
}
