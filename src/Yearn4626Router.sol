
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "./Yearn4626RouterBase.sol";

import {IERC4626Router, IYearnV2} from "./interfaces/IERC4626Router.sol";

/// @title Yearn4626Router contract
contract Yearn4626Router is IERC4626Router, Yearn4626RouterBase {
    using SafeTransferLib for ERC20;

    // Store name as bytes so it can be immutable
    bytes32 private immutable _name;

    constructor(string memory _name_, IWETH9 weth) PeripheryPayments(weth) {
        _name = bytes32(abi.encodePacked(_name_));
    }

    function name() external view returns(string memory) {
        return string(abi.encodePacked(_name));
    }

    // For the below, no approval needed, assumes vault is already max approved

    /// @inheritdoc IERC4626Router
    function depositToVault(
        IERC4626 vault,
        uint256 amount,
        address to,
        uint256 minSharesOut
    ) public payable override returns (uint256 sharesOut) {
        pullToken(ERC20(vault.asset()), amount, address(this));
        return deposit(vault, amount, to, minSharesOut);
    }

    //-------- DEPOSIT FUNCTIONS WITH DEFAULT VALUES --------\\ 

    function depositToVault(
        IERC4626 vault,
        uint256 amount,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut) {
        return depositToVault(vault, amount, msg.sender, minSharesOut);
    }

    function depositToVault(
        IERC4626 vault, 
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut) {
        return depositToVault(vault, ERC20(vault.asset()).balanceOf(msg.sender), msg.sender, minSharesOut);
    }

    function depositToVault(
        IERC4626 vault
    ) external payable returns (uint256 sharesOut) {
        uint256 assets =  ERC20(vault.asset()).balanceOf(msg.sender);
        // This give a default 1bp acceptance for loss. This is only 
        // considered safe if the vaults PPS can not be manipulated.
        uint256 minSharesOut = vault.previewDeposit(assets) * 9_999 / 10_000;
        return depositToVault(vault, assets, msg.sender, minSharesOut);
    }

    //-------- REDEEM FUNCTIONS WITH DEFAULT VALUES --------\\

    function redeem(
        IERC4626 vault,
        uint256 shares,
        uint256 minAmountOut
    ) external payable returns (uint256 amountOut) {
        return redeem(vault, shares, msg.sender, minAmountOut);
    }

    function redeem(
        IERC4626 vault
    ) external payable returns (uint256 amountOut) {
        uint256 shares = vault.balanceOf(msg.sender);
        // This give a default 1bp acceptance for loss. This is only 
        // considered safe if the vaults PPS can not be manipulated.
        uint256 minAmountOut = vault.previewRedeem(shares) * 9_999 / 10_000;
        return redeem(vault, shares, msg.sender, minAmountOut);
    }

    /// @inheritdoc IERC4626Router
    function migrate(
        IERC4626 fromVault,
        IERC4626 toVault,
        uint256 shares,
        address to,
        uint256 minSharesOut
    ) public payable override returns (uint256 sharesOut) {
        // amount out passes through so only one slippage check is needed
        uint256 amount = redeem(fromVault, shares, address(this), 0);
        return deposit(toVault, amount, to, minSharesOut);
    }

    //-------- MIGRATE FUNCTIONS WITH DEFAULT VALUES --------\\

    function migrate(
        IERC4626 fromVault,
        IERC4626 toVault,
        uint256 shares,
        address to
    ) external payable returns (uint256 sharesOut) {
        return migrate(fromVault, toVault, shares, to, 0);
    }

    function migrate(
        IERC4626 fromVault,
        IERC4626 toVault,
        uint256 shares
    ) external payable returns (uint256 sharesOut) {
        return migrate(fromVault, toVault, shares, msg.sender, 0);
    }

    function migrate(
        IERC4626 fromVault, 
        IERC4626 toVault
    ) external payable returns (uint256 sharesOut) {
        uint256 shares = fromVault.balanceOf(msg.sender);
        return migrate(fromVault, toVault, shares, msg.sender, 0);
    }

    /// @inheritdoc IERC4626Router
    function migrateV2(
        IYearnV2 fromVault,
        IERC4626 toVault,
        uint256 shares,
        address to,
        uint256 minSharesOut
    ) public payable override returns (uint256 sharesOut) {
        // amount out passes through so only one slippage check is needed
        uint256 redeemed = fromVault.withdraw(shares, address(this));
        return deposit(toVault, redeemed, to, minSharesOut);
    }

    //-------- MIGRATEV2 FUNCTIONS WITH DEFAULT VALUES --------\\

    function migrateV2(
        IYearnV2 fromVault,
        IERC4626 toVault,
        uint256 shares,
        address to
    ) external payable returns (uint256 sharesOut) {
        return migrateV2(fromVault, toVault, shares, to, 0);
    }

    function migrateV2(
        IYearnV2 fromVault,
        IERC4626 toVault,
        uint256 shares
    ) external payable returns (uint256 sharesOut) {
        return migrateV2(fromVault, toVault, shares, msg.sender, 0);
    }

    function migrateV2(
        IYearnV2 fromVault,
        IERC4626 toVault
    ) external payable returns (uint256 sharesOut) {
        uint256 shares = fromVault.balanceOf(msg.sender);
        return migrateV2(fromVault, toVault, shares, msg.sender, 0);
    }
}
