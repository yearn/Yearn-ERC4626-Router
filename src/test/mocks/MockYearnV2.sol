// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.18;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC4626} from "solmate/test/utils/mocks/MockERC4626.sol";

import {console} from "../utils/Console.sol";


contract MockYearnV2 is MockERC4626 {

    constructor(ERC20 underlying) MockERC4626(underlying, "Mock YearnStrategy", "mSTGY") {}

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) public returns(uint256) {
        return redeem(maxShares, recipient, msg.sender);
    }

    function withdraw(
        uint256 maxShares,
        address recipient
    ) external returns(uint256) {
        console.log("REcep ", recipient);
        console.log("Sender ", msg.sender);
        return redeem(maxShares, recipient, msg.sender);
    }

}
