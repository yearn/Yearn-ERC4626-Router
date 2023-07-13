// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.18;

import {IERC4626} from "./IERC4626.sol";

/// @title Yearn V3 ERC4626 interface
/// @notice Extends the normal 4626 standard with some added Yearn specific functionality
abstract contract IYearn4626 is IERC4626 {
    /*////////////////////////////////////////////////////////
                    Yearn Specific Functions
    ////////////////////////////////////////////////////////*/

    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxLoss
    ) external virtual returns (uint256 shares);

    /// @notice Yearn Specific "withdraw" with withdrawal stack included
    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxLoss,
        address[] memory strategies
    ) external virtual returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 maxLoss
    ) external virtual returns (uint256 assets);

    /// @notice Yearn Specific "redeem" with withdrawal stack included
    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 maxLoss,
        address[] memory strategies
    ) external virtual returns (uint256 assets);
}
