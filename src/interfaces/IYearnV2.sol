// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

interface IYearnV2 {
    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient, uint256 maxLoss) external returns (uint256);
}