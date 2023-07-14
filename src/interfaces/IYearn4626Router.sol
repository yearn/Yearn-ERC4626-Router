// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.18;

import "./IYearn4626.sol";
import "./IYearnV2.sol";

/** 
 @title ERC4626Router Interface
 @notice Extends the ERC4626RouterBase with specific flows to save gas
 */
interface IYearn4626Router {
    /************************** Deposit **************************/

    /** 
     @notice deposit `amount` to an ERC4626 vault.
     @param vault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param amount The amount of assets to deposit to `vault`.
     @param minSharesOut The min amount of `vault` shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws "!minShares" Error. Can call with just 'vault' to deposit max.
    */
    function depositToVault(
        IYearn4626 vault,
        uint256 amount,
        address to,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /************************** Migrate **************************/

    /** 
     @notice will redeem `shares` from one vault and deposit amountOut to a different ERC4626 vault.
     @param fromVault The ERC4626 vault to redeem shares from.
     @param toVault The ERC4626 vault to deposit assets to.
     @param shares The amount of shares to redeem from fromVault.
     @param to The destination of ownership shares.
     @param minSharesOut The min amount of toVault shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws "!minAmount", "!minShares" Errors. Can call with only 'fromVault' and 'toVault' to migrate max.
    */
    function migrate(
        IYearn4626 fromVault,
        IYearn4626 toVault,
        uint256 shares,
        address to,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /**
     @notice migrate from Yearn V2 vault to a V3 vault'.
     @param fromVault The Yearn V2 vault to withdraw from.
     @param toVault The Yearn V3 vault to deposit assets to.
     @param shares The amount of V2 shares to redeem form 'fromVault'.
     @param to The destination of ownership shares
     @param minSharesOut The min amount of 'toVault' shares to be received by 'to'.
     @return sharesOut The actual amount of 'toVault' shares received by 'to'.
     @dev throws "!minAmount", "!minShares" Errors. Can call with only 'fromVault' and 'toVault' to migrate max.
    */
    function migrateFromV2(
        IYearnV2 fromVault,
        IYearn4626 toVault,
        uint256 shares,
        address to,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);
}
