// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Script} from 'forge-std/Script.sol';
import {VaultManager} from 'contracts/VaultManager.sol';
import {XEarn} from 'contracts/xEarn.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';

contract DepositToken is Script {
  function run() external {
    vm.startBroadcast();

    address _weth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address _xEarn = 0x734245284c5B1934ca9fe7198c734DB5DB1264C0;

    address _destination = 0x10cDb5380BE2683f9E44b16fbaA73171D5DFc568;
    uint32 _destinationDomain = 1_869_640_809; // Optimism
    uint256 _amount = 0.001 ether;
    uint256 _relayerFee = 1.2 ether; // MATIC
    address _vault = 0xFaee21D0f0Af88EE72BB6d68E54a90E6EC2616de;
    uint24 _poolFee = 3000;

    IERC20(_weth).approve(_xEarn, type(uint256).max);

    XEarn(_xEarn).deposit{value: _relayerFee}(_destination, _destinationDomain, _amount, _relayerFee, _vault, _poolFee);
    vm.stopBroadcast();
  }
}
