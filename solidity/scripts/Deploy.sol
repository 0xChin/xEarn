// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Script} from 'forge-std/Script.sol';
import {VaultManager} from 'contracts/VaultManager.sol';
import {XEarn} from 'contracts/xEarn.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';

abstract contract DeployXEarn is Script {
  function _deploy(address _weth9, address _connext) internal {
    vm.startBroadcast();
    new XEarn(_weth9, _connext);
    vm.stopBroadcast();
  }
}

abstract contract DeployVaultManager is Script {
  function _deploy(address _weth9, address _swapRouter, address _connext, uint32 _mainChain) internal {
    vm.startBroadcast();
    new VaultManager(_weth9, _swapRouter, _connext, _mainChain);
    vm.stopBroadcast();
  }
}

contract DeployPolygon is DeployXEarn {
  function run() external {
    _deploy(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619, 0x11984dc4465481512eb5b777E44061C158CF2259);
  }
}

contract DeployOptimism is DeployVaultManager {
  function run() external {
    _deploy(
      0x4200000000000000000000000000000000000006,
      0xE592427A0AEce92De3Edee1F18E0157C05861564,
      0x8f7492DE823025b4CfaAB1D34c58963F2af5DEDA,
      1_886_350_457
    );
  }
}

contract DeployArbitrum is DeployVaultManager {
  function run() external {
    _deploy(
      0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
      0xE592427A0AEce92De3Edee1F18E0157C05861564,
      0xEE9deC2712cCE65174B561151701Bf54b99C24C8,
      1_886_350_457
    );
  }
}
