// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC4626} from "solmate/test/utils/mocks/MockERC4626.sol";

contract MockStrategy is MockERC4626 {

    constructor(ERC20 underlying) MockERC4626(underlying, "Mock YearnStrategy", "mSTGY") {}

    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxLoss
    ) public returns (uint256) {
        return withdraw(assets, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 maxLoss
    ) public returns (uint256) {
        return redeem(shares, receiver, owner);
    }


}
