// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "./IYearn4626.sol";

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
     @dev throws MinSharesError   
    */
    function depositToVault(
        IYearn4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /** 
     @notice deposit max assets to an ERC4626 vault.
     @param vault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param minSharesOut The min amount of `vault` shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinSharesError   
    */
    function depositMax(
        IYearn4626 vault,
        address to,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /************************** Withdraw **************************/

    /** 
     @notice withdraw `amount` to an ERC4626 vault.
     @param fromVault The ERC4626 vault to withdraw assets from.
     @param toVault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param amount The amount of assets to withdraw from fromVault.
     @param maxSharesIn The max amount of fromVault shares withdrawn by caller.
     @param minSharesOut The min amount of toVault shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MaxSharesError, MinSharesError 
    */
    function withdrawToDeposit(
        IYearn4626 fromVault,
        IYearn4626 toVault,
        address to,
        uint256 amount,
        uint256 maxSharesIn,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /************************** Redeem **************************/

    /** 
     @notice redeem `shares` to an ERC4626 vault.
     @param fromVault The ERC4626 vault to redeem shares from.
     @param toVault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param shares The amount of shares to redeem from fromVault.
     @param minSharesOut The min amount of toVault shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinAmountError, MinSharesError   
    */
    function redeemToDeposit(
        IYearn4626 fromVault,
        IYearn4626 toVault,
        address to,
        uint256 shares,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /** 
     @notice redeem max shares to an ERC4626 vault.
     @param vault The ERC4626 vault to redeem shares from.
     @param to The destination of assets.
     @param minAmountOut The min amount of assets received by `to`.
     @return amountOut the amount of assets received by `to`.
     @dev throws MinAmountError   
    */
    function redeemMax(
        IYearn4626 vault,
        address to,
        uint256 minAmountOut
    ) external payable returns (uint256 amountOut);
}