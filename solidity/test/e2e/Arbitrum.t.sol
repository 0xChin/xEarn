// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {ICurveCryptoSwap} from 'interfaces/peripherals/ICurveCryptoSwap.sol';
import {console} from 'forge-std/console.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';
import {IERC4626} from 'interfaces/tokens/IERC4626.sol';
import {IWETH9} from 'interfaces/tokens/IWETH9.sol';
import {VaultManager} from 'contracts/VaultManager.sol';

contract E2EArbitrumVaults is DSTestFull {
  uint256 internal constant _FORK_BLOCK = 71_296_637;

  address internal _tricryptoPoolAddress = _label(0x960ea3e3C7FB317332d990873d354E18d7645590, 'Curve: Tricrypto Pool');
  address internal _tricryptoTokenAddress = _label(0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2, 'Curve: Tricrypto Token');
  address internal _tricryptoZap = _label(0xF97c707024ef0DD3E77a0824555a46B622bfB500, 'Curve: Tricrypto Zap');
  address internal _tricryptoVaultAddress = _label(0x239e14A19DFF93a17339DCC444f74406C17f8E67, 'Yearn: Tricrypto Vault');
  address internal _user = _label('_user');

  address internal _weth9Address = _label(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1, 'WETH9');
  address internal _swapRouterAddress = _label(0xE592427A0AEce92De3Edee1F18E0157C05861564, 'Uniswap: Swap Router');

  function setUp() public {
    vm.startPrank(_user);
    vm.createSelectFork(vm.rpcUrl('arbitrum'), _FORK_BLOCK);
  }

  function test_Curve_Token_Vault() public {
    // Create contract
    VaultManager _vaultManager = new VaultManager(
            _weth9Address,
            _swapRouterAddress,
            _user // Sending user as connext router for the sake of simplicity
        );

    // Add mock origin and origin sender to allowlist
    _vaultManager.addToAllowlist(0, address(0));

    // Get some WETH
    vm.deal(_user, 1 ether);
    IWETH9 _weth9 = IWETH9(_weth9Address);
    _weth9.deposit{value: 1 ether}();

    // Deposit
    _weth9.approve(address(_vaultManager), 1 ether);
    bytes memory _callData = abi.encode(
      _user,
      _tricryptoTokenAddress,
      _tricryptoVaultAddress,
      _tricryptoPoolAddress,
      VaultManager.OperationType.DepositCurveLP
    );
    _vaultManager.xReceive(bytes32(0), 1 ether, _weth9Address, address(0), 0, _callData);

    // Withdraw
    _callData = abi.encode(
      _user,
      _tricryptoTokenAddress,
      _tricryptoVaultAddress,
      _tricryptoPoolAddress,
      VaultManager.OperationType.WithdrawCurveLP
    );
    _vaultManager.xReceive(bytes32(0), 0, address(0), address(0), 0, _callData);
  }
}
