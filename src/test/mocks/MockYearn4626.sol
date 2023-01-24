// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC4626} from "solmate/test/utils/mocks/MockERC4626.sol";

contract MockYearn4626 is MockERC4626 {
    struct StrategyParams {
        uint256 activation;
        uint256 last_report;
        uint256 current_debt;
        uint256 max_debt;
    }

    mapping(address => StrategyParams) public strategies;

    constructor(ERC20 underlying) MockERC4626(underlying, "Mock Yearn4626", "yMTKN") {}

    /// @notice Yearn Specific "withdraw" with withdrawal stack included
    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        address[] memory /*_strategies*/
    ) public returns (uint256 shares) {
        return withdraw(assets, receiver, owner);
    }

    /// @notice Yearn Specific "redeem" with withdrawal stack included
    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        address[] memory /*_strategies*/
    ) public returns (uint256 assets) {
        return redeem(shares, receiver, owner);
    }

    function addStrategy(address strategy) external {
        strategies[strategy] = StrategyParams(block.timestamp, block.timestamp, 0, 0);
    }

    function removeStrategy(address strategy) external {
        strategies[strategy] = StrategyParams(0, 0, 0, 0);
    }
}
