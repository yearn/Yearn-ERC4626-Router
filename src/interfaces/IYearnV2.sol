// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.18;

import {ERC20} from "solmate/tokens/ERC20.sol";

abstract contract IYearnV2 is ERC20 {
    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external virtual returns (uint256);

    function withdraw(uint256 maxShares) external virtual returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external virtual returns (uint256);

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external virtual returns (uint256);
}
