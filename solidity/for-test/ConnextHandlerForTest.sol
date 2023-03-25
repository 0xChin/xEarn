//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {IXReceiver} from 'connext/IXReceiver.sol';
import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';

contract ConnextHandlerForTest {
  uint32 public origin;

  constructor(uint32 _origin) {
    origin = _origin;
  }

  function xcall(
    uint32, // _destination, unique identifier for destination domain
    address _to, // recipient of funds, where calldata will be executed
    address _asset, // _asset, asset being transferred
    address, // _delegate, permissioned address to recover in edgecases on destination domain
    uint256 _amount, // _amount, amount being transferred
    uint256, // _slippage, slippage in bps
    bytes calldata _callData // to be executed on _to on the destination domain
  ) external payable returns (bytes32) {
    if (IERC20(_asset).balanceOf(address(this)) < _amount) {
      IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
    }

    IERC20(_asset).transfer(_to, _amount);

    if (_callData.length > 0) {
      IXReceiver(_to).xReceive({
        _transferId: 0,
        _amount: _amount,
        _asset: _asset,
        _originSender: address(this),
        _origin: origin,
        _callData: _callData
      });
    }

    return bytes32(abi.encode('random'));
  }
}
