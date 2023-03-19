// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IERC4626 {
  event Deposit(address indexed _caller, address indexed _owner, uint256 _assets, uint256 _shares);

  event Withdraw(
    address indexed _caller, address indexed _receiver, address indexed _owner, uint256 _assets, uint256 _shares
  );

  function asset() external view returns (address _assetTokenAddress);

  function totalAssets() external view returns (uint256 _totalManagedAssets);

  function convertToShares(uint256 _assets) external view returns (uint256 _shares);

  function convertToAssets(uint256 _shares) external view returns (uint256 _assets);

  function maxDeposit(address _receiver) external view returns (uint256 _maxAssets);

  function previewDeposit(uint256 _assets) external view returns (uint256 _shares);

  function deposit() external returns (uint256 _shares);

  function deposit(uint256 _assets) external returns (uint256 _shares);

  function deposit(uint256 _assets, address _receiver) external returns (uint256 _shares);

  function maxMint(address _receiver) external view returns (uint256 _maxShares);

  function previewMint(uint256 _shares) external view returns (uint256 _assets);

  function mint(uint256 _shares, address _receiver) external returns (uint256 _assets);

  function maxWithdraw(address _owner) external view returns (uint256 _maxAssets);

  function previewWithdraw(uint256 _assets) external view returns (uint256 _shares);

  function withdraw(uint256 _assets, address _receiver, address _owner) external returns (uint256 _shares);

  function maxRedeem(address _owner) external view returns (uint256 _maxShares);

  function previewRedeem(uint256 _shares) external view returns (uint256 _assets);

  function redeem(uint256 _shares, address _receiver, address _owner) external returns (uint256 _assets);
}
