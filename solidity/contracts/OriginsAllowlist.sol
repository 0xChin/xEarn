// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {Ownable} from 'openzeppelin-contracts/access/Ownable.sol';

contract OriginsAllowlist is Ownable {
  error WrongLength();

  mapping(uint32 => mapping(address => bool)) public allowlist;

  function addToAllowlist(uint32 _origin, address _sender) external onlyOwner {
    allowlist[_origin][_sender] = true;
  }

  function addToAllowlist(uint32[] memory _origins, address[] memory _senders) external onlyOwner {
    if (_origins.length != _senders.length) revert WrongLength();
    for (uint256 i = 0; i < _origins.length; i++) {
      allowlist[_origins[i]][_senders[i]] = true;
    }
  }

  function removeFromAllowlist(uint32 _origin, address _address) external onlyOwner {
    delete allowlist[_origin][_address];
  }

  function removeFromAllowlist(uint32[] memory _origins, address[] memory _senders) external onlyOwner {
    if (_origins.length != _senders.length) revert WrongLength();
    for (uint256 i = 0; i < _origins.length; i++) {
      delete allowlist[_origins[i]][_senders[i]];
    }
  }
}
