// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC4626} from "solmate/test/utils/mocks/MockERC4626.sol";

contract MockStrategy is MockERC4626 {

    constructor(ERC20 underlying) MockERC4626(underlying, "Mock YearnStrategy", "mSTGY") {}

}
