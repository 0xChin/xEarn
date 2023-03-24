// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {console} from 'forge-std/console.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';
import {IERC4626} from 'interfaces/tokens/IERC4626.sol';
import {IWETH9} from 'interfaces/tokens/IWETH9.sol';

import {VaultManager} from 'contracts/VaultManager.sol';
import {ConnextHandlerForTest} from 'for-test/ConnextHandlerForTest.sol';

contract E2EOptimismVaults is DSTestFull {
  uint256 internal constant _FORK_BLOCK = 82_066_571;

  address internal _usdtVaultAddress = _label(0xFaee21D0f0Af88EE72BB6d68E54a90E6EC2616de, 'Yearn: USDT Vault');
  address internal _user = _label('user');

  address internal _weth9Address = _label(0x4200000000000000000000000000000000000006, 'WETH9');
  address internal _swapRouterAddress = _label(0xE592427A0AEce92De3Edee1F18E0157C05861564, 'Uniswap: Swap Router');

  function setUp() public {
    vm.startPrank(_user);
    vm.createSelectFork(vm.rpcUrl('optimism'), _FORK_BLOCK);
  }

  function test_Token_Vault() public {
    // Create mock connext handler
    ConnextHandlerForTest _connext = new ConnextHandlerForTest();

    // Create contract
    VaultManager _vaultManager = new VaultManager(
            _weth9Address,
            _swapRouterAddress,
            address(_connext),
            uint32(1886350457) // Polygon domain
        );

    // Get some WETH
    vm.deal(_user, 1 ether);
    IWETH9 _weth9 = IWETH9(_weth9Address);
    _weth9.deposit{value: 1 ether}();

    // Deposit
    _weth9.transfer(address(_connext), 1 ether);
    bytes memory _callData = abi.encode(_user, _usdtVaultAddress, 0, 3000, VaultManager.OperationType.DepositToken);
    _connext.xcall(0, address(_vaultManager), _weth9Address, address(0), 1 ether, 0, _callData);

    // Withdraw
    _callData = abi.encode(_user, _usdtVaultAddress, 0.3 ether, 3000, VaultManager.OperationType.WithdrawToken);
    _connext.xcall(0, address(_vaultManager), _weth9Address, address(0), 0, 0, _callData);
  }
}
