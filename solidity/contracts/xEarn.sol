// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IConnext} from 'connext/IConnext.sol';
import {VaultManager} from 'contracts/VaultManager.sol';
import {IWETH9} from 'interfaces/tokens/IWETH9.sol';

// I call this the anti-access-controls contract. It seems I had issues with my time management during this hackathon so I'm kind of rushing
contract XEarn {
  IConnext public immutable connext;
  IWETH9 public immutable weth;

  constructor(address _weth9, address _connext) {
    connext = IConnext(_connext);
    weth = IWETH9(_weth9);
  }

  function deposit(
    address _target,
    uint32 _destinationDomain,
    uint256 _amount,
    uint256 _relayerFee,
    address _vault,
    uint24 _poolFee
  ) external payable {
    weth.transferFrom(msg.sender, address(this), _amount);
    weth.approve(address(connext), _amount);

    bytes memory _callData = abi.encode(msg.sender, _vault, 0, _poolFee, VaultManager.OperationType.DepositToken); // Relayer fee doesn't matter in deposits, just in withdrawals

    connext.xcall{value: _relayerFee}(
      _destinationDomain, // _destination: Domain ID of the destination chain
      _target, // _to: address of the target contract
      address(weth), // _asset: address of the token contract
      msg.sender, // _delegate: address that can revert or forceLocal on destination
      _amount, // _amount: amount of tokens to transfer
      500, // _slippage: max slippage the user will accept in BPS (e.g. 300 = 3%)
      _callData // _callData: the encoded calldata to send
    );
  }

  function deposit(
    address _target,
    uint32 _destinationDomain,
    uint256 _amount,
    uint256 _relayerFee,
    address _vault,
    address _curvePool
  ) external payable {
    weth.transferFrom(msg.sender, address(this), _amount);
    weth.approve(address(connext), _amount);

    bytes memory _callData = abi.encode(msg.sender, _vault, 0, _curvePool, VaultManager.OperationType.DepositCurveLP); // Relayer fee doesn't matter in deposits, just in withdrawals

    connext.xcall{value: _relayerFee}(
      _destinationDomain, // _destination: Domain ID of the destination chain
      _target, // _to: address of the target contract
      address(weth), // _asset: address of the token contract
      msg.sender, // _delegate: address that can revert or forceLocal on destination
      _amount, // _amount: amount of tokens to transfer
      500, // _slippage: max slippage the user will accept in BPS (e.g. 300 = 3%)
      _callData // _callData: the encoded calldata to send
    );
  }

  function withdraw(
    address _target,
    uint32 _destinationDomain,
    uint256 _amount,
    uint256 _relayerFee,
    uint256 _xRelayerFee,
    address _vault,
    uint24 _poolFee
  ) external payable {
    bytes memory _callData =
      abi.encode(msg.sender, _vault, _xRelayerFee, _poolFee, VaultManager.OperationType.WithdrawToken);

    connext.xcall{value: _relayerFee}(
      _destinationDomain, // _destination: Domain ID of the destination chain
      _target, // _to: address of the target contract
      address(weth), // _asset: address of the token contract
      msg.sender, // _delegate: address that can revert or forceLocal on destination
      _amount, // _amount: amount of tokens to transfer
      500, // _slippage: max slippage the user will accept in BPS (e.g. 300 = 3%)
      _callData // _callData: the encoded calldata to send
    );
  }

  function withdraw(
    address _target,
    uint32 _destinationDomain,
    uint256 _amount,
    uint256 _relayerFee,
    uint256 _xRelayerFee,
    address _vault,
    address _curvePool
  ) external payable {
    bytes memory _callData =
      abi.encode(msg.sender, _vault, _xRelayerFee, _curvePool, VaultManager.OperationType.WithdrawCurveLP);

    connext.xcall{value: _relayerFee}(
      _destinationDomain, // _destination: Domain ID of the destination chain
      _target, // _to: address of the target contract
      address(weth), // _asset: address of the token contract
      msg.sender, // _delegate: address that can revert or forceLocal on destination
      _amount, // _amount: amount of tokens to transfer
      500, // _slippage: max slippage the user will accept in BPS (e.g. 300 = 3%)
      _callData // _callData: the encoded calldata to send
    );
  }
}
