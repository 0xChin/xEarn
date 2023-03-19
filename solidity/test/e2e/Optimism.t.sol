// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {console} from 'forge-std/console.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';
import {IERC4626} from 'interfaces/tokens/IERC4626.sol';

contract E2EOptimismVaults is DSTestFull {
  uint256 internal constant _FORK_BLOCK = 82_066_571;

  address internal _usdtAddress = _label(0x94b008aA00579c1307B0EF2c499aD98a8ce58e58, 'ERC20: USDT');
  address internal _usdtVaultAddress = _label(0xFaee21D0f0Af88EE72BB6d68E54a90E6EC2616de, 'Yearn: USDT Vault');
  address internal _user = _label('user');

  function setUp() public {
    vm.startPrank(_user);
    vm.createSelectFork(vm.rpcUrl('optimism'), _FORK_BLOCK);
    deal(_usdtAddress, _user, 1 ether);
  }

  function test_Usdt_Deposit() public {
    IERC20 _usdt = IERC20(_usdtAddress);
    IERC4626 _usdtVault = IERC4626(_usdtVaultAddress);

    _usdt.approve(_usdtVaultAddress, type(uint256).max);
    _usdtVault.deposit();
  }
}
