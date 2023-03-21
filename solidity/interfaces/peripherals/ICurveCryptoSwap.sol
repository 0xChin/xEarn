// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface ICurveCryptoSwap {
  function add_liquidity(uint256[3] calldata _amounts, uint256 _minMintAmount) external payable;
  function remove_liquidity_one_coin(uint256 _amount, uint256 _i, uint256 _minAmount) external;
}
