// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "./Yearn4626RouterBase.sol";

import {ENSReverseRecord} from "./utils/ENSReverseRecord.sol";
import {IYearn4626Router} from "./interfaces/IYearn4626Router.sol";

/// @title Yearn4626Router contract
contract Yearn4626Router is IYearn4626Router, Yearn4626RouterBase, ENSReverseRecord {
    using SafeTransferLib for ERC20;

    constructor(string memory name, IWETH9 weth) ENSReverseRecord(name) PeripheryPayments(weth) {}

    // For the below, no approval needed, assumes vault is already max approved

    /// @inheritdoc IYearn4626Router
    function depositToVault(
        IYearn4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external payable override returns (uint256 sharesOut) {
        pullToken(ERC20(vault.asset()), amount, address(this));
        return deposit(vault, to, amount, minSharesOut);
    }

    /// @inheritdoc IYearn4626Router
    function withdrawToDeposit(
        IYearn4626 fromVault,
        IYearn4626 toVault,
        address to,
        uint256 amount,
        uint256 maxSharesIn,
        uint256 minSharesOut
    ) external payable override returns (uint256 sharesOut) {
        withdraw(fromVault, address(this), amount, maxSharesIn);
        return deposit(toVault, to, amount, minSharesOut);
    }

    /// @inheritdoc IYearn4626Router
    function redeemToDeposit(
        IYearn4626 fromVault,
        IYearn4626 toVault,
        address to,
        uint256 shares,
        uint256 minSharesOut
    ) external payable override returns (uint256 sharesOut) {
        // amount out passes through so only one slippage check is needed
        uint256 amount = redeem(fromVault, address(this), shares, 0);
        return deposit(toVault, to, amount, minSharesOut);
    }

    /// @inheritdoc IYearn4626Router
    function depositMax(
        IYearn4626 vault,
        address to,
        uint256 minSharesOut
    ) public payable override returns (uint256 sharesOut) {
        ERC20 asset = ERC20(vault.asset());
        uint256 assetBalance = asset.balanceOf(msg.sender);
        uint256 maxDeposit = vault.maxDeposit(to);
        uint256 amount = maxDeposit < assetBalance ? maxDeposit : assetBalance;
        pullToken(asset, amount, address(this));
        return deposit(vault, to, amount, minSharesOut);
    }

    /// @inheritdoc IYearn4626Router
    function redeemMax(
        IYearn4626 vault,
        address to,
        uint256 minAmountOut
    ) public payable override returns (uint256 amountOut) {
        uint256 shareBalance = vault.balanceOf(msg.sender);
        uint256 maxRedeem = vault.maxRedeem(msg.sender);
        uint256 amountShares = maxRedeem < shareBalance ? maxRedeem : shareBalance;
        return redeem(vault, to, amountShares, minAmountOut);
    }
}
