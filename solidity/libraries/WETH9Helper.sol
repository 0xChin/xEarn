// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IWETH9} from 'interfaces/tokens/IWETH9.sol';

library WETH9Helper {
  function pullEthFromSender(uint256 _amount, address _weth) internal {
    pullEth(_amount, msg.sender, _weth);
  }

  function pullEth(uint256 _amount, address _from, address _weth) internal {
    IWETH9(_weth).transferFrom(_from, address(this), _amount);
  }
}
