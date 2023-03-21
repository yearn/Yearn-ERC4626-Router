// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import {IERC4626RouterBase, IERC4626} from "./interfaces/IERC4626RouterBase.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {SelfPermit} from "./external/SelfPermit.sol";
import {Multicall} from "./external/Multicall.sol";
import {PeripheryPayments, IWETH9} from "./external/PeripheryPayments.sol";

/// @title ERC4626 Router Base Contract
abstract contract Yearn4626RouterBase is
    IERC4626RouterBase,
    SelfPermit,
    Multicall,
    PeripheryPayments
{
    using SafeTransferLib for ERC20;

    /// @inheritdoc IERC4626RouterBase
    function mint(
        IERC4626 vault,
        uint256 shares,
        address to,
        uint256 maxAmountIn
    ) public payable virtual override returns (uint256 amountIn) {
        require ((amountIn = vault.mint(shares, to)) <= maxAmountIn, "!MaxAmount");
    }

    /// @inheritdoc IERC4626RouterBase
    function deposit(
        IERC4626 vault,
        uint256 amount,
        address to,
        uint256 minSharesOut
    ) public payable virtual override returns (uint256 sharesOut) {
        require ((sharesOut = vault.deposit(amount, to)) >= minSharesOut, "!MinShares");
    }

    /// @inheritdoc IERC4626RouterBase
    function withdraw(
        IERC4626 vault,
        uint256 amount,
        address to,
        uint256 maxSharesOut
    ) public payable virtual override returns (uint256 sharesOut) {
        require ((sharesOut = vault.withdraw(amount, to, msg.sender)) <= maxSharesOut, "!MaxShares");
    }

    /// @inheritdoc IERC4626RouterBase
    function redeem(
        IERC4626 vault,
        uint256 shares,
        address to,
        uint256 minAmountOut
    ) public payable virtual override returns (uint256 amountOut) {
        require ((amountOut = vault.redeem(shares, to, msg.sender)) >= minAmountOut, "!MinAmount");
    }
}
