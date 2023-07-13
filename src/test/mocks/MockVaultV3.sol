// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.18;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {MockStrategy} from "./MockStrategy.sol";

contract MockVaultV3 is ERC4626 {
    struct StrategyParams {
        uint256 activation;
        uint256 last_report;
        uint256 current_debt;
        uint256 max_debt;
    }

    mapping(address => StrategyParams) public strategies;

    uint256 public totalDebt;

    constructor(ERC20 underlying) ERC4626(underlying, "Mock Yearn4626", "yMTKN") {}

    function totalAsset() public view returns (uint256) {
        return ERC20(asset).balanceOf(address(this));
    }

    function totalAssets() public override view returns(uint256) {
        return totalAsset() + totalDebt;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxLoss
    ) public returns (uint256) {
        return withdraw(assets, receiver, owner);
    }

    /// @notice Yearn Specific "withdraw" with withdrawal stack included
    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256 maxLoss,
        address[] memory _strategies
    ) public returns (uint256 shares) {
        uint256 i;
        while(totalAsset() < assets && i < _strategies.length) {
            MockStrategy mockStrategy = MockStrategy(_strategies[i]);
            uint256 toWithdraw = mockStrategy.maxWithdraw(address(this)) > assets ? assets : mockStrategy.maxWithdraw(address(this));
            mockStrategy.withdraw(toWithdraw, address(this), address(this));
            totalDebt -= toWithdraw;
            i++;
        }
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

    /// @notice Yearn Specific "redeem" with withdrawal stack included
    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 maxLoss,
        address[] memory _strategies
    ) public returns (uint256 assets) {
        uint256 i;
        // we assume no growth so assets == shares
        while(totalAsset() < shares && i < _strategies.length) {
            MockStrategy mockStrategy = MockStrategy(_strategies[i]);
            uint256 toRedeem = mockStrategy.maxRedeem(address(this)) > shares ? shares : mockStrategy.maxRedeem(address(this));
            mockStrategy.redeem(toRedeem, address(this), address(this));
            totalDebt -= toRedeem;
            i++;
        }
        return redeem(shares, receiver, owner);
    }

    function addStrategy(address strategy) external {
        strategies[strategy] = StrategyParams(block.timestamp, block.timestamp, 0, 0);
    }

    function removeStrategy(address strategy) external {
        strategies[strategy] = StrategyParams(0, 0, 0, 0);
    }

    function updateDebt(address _strategy, uint256 _amount) external {
        require(totalAsset() >= _amount, "not enough asset");
        asset.approve(_strategy, _amount);
        MockStrategy(_strategy).deposit(_amount, address(this));
        totalDebt += _amount;
    }
}
