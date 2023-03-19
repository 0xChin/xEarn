// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {DSTestFull} from 'test/utils/DSTestFull.sol';
import {ICurveCryptoSwap} from 'interfaces/peripherals/ICurveCryptoSwap.sol';
import {console} from 'forge-std/console.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';
import {IERC4626} from 'interfaces/tokens/IERC4626.sol';

contract E2EArbitrumVaults is DSTestFull {
  uint256 internal constant _FORK_BLOCK = 71_296_637;

  address internal _tricryptoZapAddress = _label(0xF97c707024ef0DD3E77a0824555a46B622bfB500, 'Curve: Tricrypto Zap');
  address internal _tricryptoTokenAddress = _label(0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2, 'Curve: Tricrypto Token');
  address internal _tricryptoVaultAddress = _label(0x239e14A19DFF93a17339DCC444f74406C17f8E67, 'Yearn: Tricrypto Vault');
  address internal _user = _label('_user');

  function setUp() public {
    vm.startPrank(_user);
    vm.createSelectFork(vm.rpcUrl('arbitrum'), _FORK_BLOCK);
    vm.deal(_user, 1 ether);
  }

  function test_Tricrypto_Deposit() public {
    ICurveCryptoSwap _tricryptoZap = ICurveCryptoSwap(_tricryptoZapAddress);
    IERC20 _tricryptoToken = IERC20(_tricryptoTokenAddress);
    IERC4626 _tricryptoVault = IERC4626(_tricryptoVaultAddress);

    uint256[3] memory _amounts = [0, 0, uint256(1 ether)];
    _tricryptoZap.add_liquidity{value: 1 ether}(_amounts, 0);

    _tricryptoToken.approve(_tricryptoVaultAddress, _tricryptoToken.balanceOf(_user));
    _tricryptoVault.deposit();
  }
}
