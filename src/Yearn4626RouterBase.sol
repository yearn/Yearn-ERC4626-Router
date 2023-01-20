// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import {IYearn4626RouterBase} from "./interfaces/IYearn4626RouterBase.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {WithdrawalStack, IYearn4626} from "./WithdrawalStack.sol";
import {SelfPermit} from "./external/SelfPermit.sol";
import {Multicall} from "./external/Multicall.sol";
import {PeripheryPayments, IWETH9} from "./external/PeripheryPayments.sol";

/// @title ERC4626 Router Base Contract
abstract contract Yearn4626RouterBase is IYearn4626RouterBase, WithdrawalStack, SelfPermit, Multicall, PeripheryPayments {
    using SafeTransferLib for ERC20;

    /// @inheritdoc IYearn4626RouterBase
    function mint(
        IYearn4626 vault,
        address to,
        uint256 shares,
        uint256 maxAmountIn
    ) public payable virtual override returns (uint256 amountIn) {
        if ((amountIn = vault.mint(shares, to)) > maxAmountIn) {
            revert MaxAmountError();
        }
    }

    /// @inheritdoc IYearn4626RouterBase
    function deposit(
        IYearn4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) public payable virtual override returns (uint256 sharesOut) {
        if ((sharesOut = vault.deposit(amount, to)) < minSharesOut) {
            revert MinSharesError();
        }
    }

    /// @inheritdoc IYearn4626RouterBase
    function withdraw(
        IYearn4626 vault,
        address to,
        uint256 amount,
        uint256 maxSharesOut
    ) public payable virtual override returns (uint256 sharesOut) {
        if ((sharesOut = vault.withdraw(amount, to, msg.sender, withdrawalStack[address(vault)])) > maxSharesOut) {
            revert MaxSharesError();
        }
    }

    /// @inheritdoc IYearn4626RouterBase
    function redeem(
        IYearn4626 vault,
        address to,
        uint256 shares,
        uint256 minAmountOut
    ) public payable virtual override returns (uint256 amountOut) {
        if ((amountOut = vault.redeem(shares, to, msg.sender, withdrawalStack[address(vault)])) < minAmountOut) {
            revert MinAmountError();
        }
    }
}
