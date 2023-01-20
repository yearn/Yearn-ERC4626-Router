// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import {IERC4626} from "./IERC4626.sol";

/// @title Yearn V3 ERC4626 interface
/// @notice Extends the normal 4626 standard with some added Yearn specific functionality
abstract contract IYearn4626 is IERC4626 {
    /*////////////////////////////////////////////////////////
                    Yearn Specific Functions
    ////////////////////////////////////////////////////////*/

    /// @notice Struct that holds the info for each strategy that
    /// has been added to the vault
    struct StrategyParams {
        uint256 activation;
        uint256 last_report;
        uint256 current_debt;
        uint256 max_debt;
    }

    /// @notice Return the StrategyParams struct for the corresponding strategy
    /// if it has been added to the vault.
    function strategies(address strategy) external view virtual returns (StrategyParams memory);

    /// @notice Yearn Specific "withdraw" with withdrawal stack included
    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        address[] memory strategies
    ) external virtual returns (uint256 shares);

    /// @notice Yearn Specific "redeem" with withdrawal stack included
    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        address[] memory strategies
    ) external virtual returns (uint256 assets);
}
