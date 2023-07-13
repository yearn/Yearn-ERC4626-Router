
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.18;

import "./Yearn4626RouterBase.sol";

import {IYearn4626Router, IYearnV2} from "./interfaces/IYearn4626Router.sol";

/// @title Yearn4626Router contract
contract Yearn4626Router is IYearn4626Router, Yearn4626RouterBase {
    using SafeTransferLib for ERC20;

    // Store name as bytes so it can be immutable
    bytes32 private immutable _name;

    constructor(string memory _name_, IWETH9 weth) PeripheryPayments(weth) {
        _name = bytes32(abi.encodePacked(_name_));
    }

    // Getter function to unpack stored name.
    function name() external view returns(string memory) {
        return string(abi.encodePacked(_name));
    }

    // For the below, no approval needed, assumes vault is already max approved

    /// @inheritdoc IYearn4626Router
    function depositToVault(
        IYearn4626 vault,
        uint256 amount,
        address to,
        uint256 minSharesOut
    ) public payable override returns (uint256 sharesOut) {
        pullToken(ERC20(vault.asset()), amount, address(this));
        return deposit(vault, amount, to, minSharesOut);
    }

    //-------- DEPOSIT FUNCTIONS WITH DEFAULT VALUES --------\\ 

    /**
    * @notice Deposits into vault using msg.sender as the default `to` 
    * variable.
    * @dev See {depositToVault} in IYearn4626Router.
    */
    function depositToVault(
        IYearn4626 vault,
        uint256 amount,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut) {
        return depositToVault(vault, amount, msg.sender, minSharesOut);
    }

    /**
    * @notice Deposits into vault using msg.sender as the default `to` 
    * variable and the full balance of msg.sender as the `amount`.
    * @dev See {depositToVault} in IYearn4626Router.
    */
    function depositToVault(
        IYearn4626 vault, 
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut) {
        return depositToVault(vault, ERC20(vault.asset()).balanceOf(msg.sender), msg.sender, minSharesOut);
    }

    /**
    * @notice Deposits into vault using msg.sender as the default `to` 
    * variable, the full balance of msg.sender as the `amount` and a
    * default slippage of 1 Basis point.
    * @dev See {depositToVault} in IYearn4626Router.
    * 
    * NOTE: The slippage tollerance is only useful if {previewDeposit}
    * cannot be manipulated for the `vault`.
    */
    function depositToVault(
        IYearn4626 vault
    ) external payable returns (uint256 sharesOut) {
        uint256 assets =  ERC20(vault.asset()).balanceOf(msg.sender);
        // This give a default 1Basis point acceptance for loss. This is only 
        // considered safe if the vaults PPS can not be manipulated.
        uint256 minSharesOut = vault.previewDeposit(assets) * 9_999 / 10_000;
        return depositToVault(vault, assets, msg.sender, minSharesOut);
    }

    //-------- REDEEM FUNCTIONS WITH DEFAULT VALUES --------\\

    /**
    * @notice Redeems from the vault using msg.sender as the default 
    * `receiver` variable.
    * @dev See {redeem} in IYearn4626RouterBase.
    */
    function redeem(
        IYearn4626 vault,
        uint256 shares,
        uint256 maxLoss
    ) external payable returns (uint256) {
        return redeem(vault, shares, msg.sender, maxLoss);
    }

    /**
    * @notice Redeems from the vault using msg.sender as the default 
    * `receiver` variable and the full balance of msg.sender as `shares`.
    * @dev See {redeem} in IYearn4626RouterBase.
    */
    function redeem(
        IYearn4626 vault,
        uint256 maxLoss
    ) external payable returns (uint256) {
        uint256 shares = vault.balanceOf(msg.sender);
        return redeem(vault, shares, msg.sender, maxLoss);
    }

    /**
    * @notice Redeems from the vault using msg.sender as the default 
    * `receiver` variable, the full balance of msg.sender as `shares`
    * and a default maxLoss of 1 Basis point.
    * @dev See {redeem} in IYearn4626RouterBase.
    */
    function redeem(
        IYearn4626 vault
    ) external payable returns (uint256) {
        uint256 shares = vault.balanceOf(msg.sender);
        return redeem(vault, shares, msg.sender, 1);
    }

    /// @inheritdoc IYearn4626Router
    function migrate(
        IYearn4626 fromVault,
        IYearn4626 toVault,
        uint256 shares,
        address to,
        uint256 minSharesOut
    ) public payable override returns (uint256 sharesOut) {
        // amount out passes through so only one slippage check is needed
        uint256 amount = redeem(fromVault, shares, address(this), 10_000);
        return deposit(toVault, amount, to, minSharesOut);
    }

    //-------- MIGRATE FUNCTIONS WITH DEFAULT VALUES --------\\

    /**
    * @notice Migrates an underlying from one vault to another using msg.sender 
    * as the default `to` variable.
    * @dev See {migrate} in IYearn4626Router.
    */
    function migrate(
        IYearn4626 fromVault,
        IYearn4626 toVault,
        uint256 shares,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut) {
        return migrate(fromVault, toVault, shares, msg.sender, minSharesOut);
    }

    /**
    * @notice Migrates an underlying from one vault to another using msg.sender 
    * as the default `to` variable and the full balance of msg.sender as `shares`.
    * @dev See {migrate} in IYearn4626Router.
    */
    function migrate(
        IYearn4626 fromVault,
        IYearn4626 toVault,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut) {
        uint256 shares = fromVault.balanceOf(msg.sender);
        return migrate(fromVault, toVault, shares, msg.sender, minSharesOut);
    }

    /**
    * @notice Migrates an underlying from one vault to another using msg.sender 
    * as the default `to` variable, the full balance of msg.sender as `shares`
    * and no minimumSharesOut.
    * @dev See {migrate} in IYearn4626Router.
    */
    function migrate(
        IYearn4626 fromVault, 
        IYearn4626 toVault
    ) external payable returns (uint256 sharesOut) {
        uint256 shares = fromVault.balanceOf(msg.sender);
        return migrate(fromVault, toVault, shares, msg.sender, 0);
    }

    /// @inheritdoc IYearn4626Router
    function migrateV2(
        IYearnV2 fromVault,
        IYearn4626 toVault,
        uint256 shares,
        address to,
        uint256 minSharesOut
    ) public payable override returns (uint256 sharesOut) {
        // V2 can't specify owner so we need to first pull the shares
        fromVault.transferFrom(msg.sender, address(this), shares);
        // amount out passes through so only one slippage check is needed
        uint256 redeemed = fromVault.withdraw(shares, address(this));
        return deposit(toVault, redeemed, to, minSharesOut);
    }

    //-------- MIGRATEV2 FUNCTIONS WITH DEFAULT VALUES --------\\

    /**
    * @notice Migrates an underlying from a V2 vault to a V3 vault using
    * msg.sender as the default `to` variable.
    * @dev See {migrateV2} in IYearn4626Router.
    */
    function migrateV2(
        IYearnV2 fromVault,
        IYearn4626 toVault,
        uint256 shares,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut) {
        return migrateV2(fromVault, toVault, shares, msg.sender, minSharesOut);
    }

    /**
    * @notice Migrates an underlying from a V2 vault to a V3 vault using
    * msg.sender as the default `to` variable and the full balance of msg.sender
    * as the `shares`.
    * @dev See {migrateV2} in IYearn4626Router.
    */
    function migrateV2(
        IYearnV2 fromVault,
        IYearn4626 toVault,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut) {
        uint256 shares = fromVault.balanceOf(msg.sender);
        return migrateV2(fromVault, toVault, shares, msg.sender, minSharesOut);
    }

    /**
    * @notice Migrates an underlying from a V2 vault to a V3 vault using
    * msg.sender as the default `to` variable, the full balance of msg.sender
    * as the `shares` and no minSharesOut.
    * @dev See {migrateV2} in IYearn4626Router.
    */
    function migrateV2(
        IYearnV2 fromVault,
        IYearn4626 toVault
    ) external payable returns (uint256 sharesOut) {
        uint256 shares = fromVault.balanceOf(msg.sender);
        return migrateV2(fromVault, toVault, shares, msg.sender, 0);
    }
}
