// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import {IYearn4626} from "./interfaces/IYearn4626.sol";
import {IWithdrawalStack} from "./interfaces/IWithdrawalStack.sol";

/// @title Withdrawal Stack Contract for YearnV3 Router
abstract contract WithdrawalStack is IWithdrawalStack {
    address public governance;
    address public pendingGovernance;

    // Max size of array the Vaults will accept as a paramater
    uint256 internal constant MAX_WITHDRAWAL_STACK_SIZE = 10;

    // Mapping of a vault address to the array repersenting its withdrawal stack
    mapping(address => address[]) public withdrawalStack;

    modifier onlyGovernance() {
        checkGovernance();
        _;
    }

    function checkGovernance() internal view {
        if (msg.sender != governance) revert NotAuthorized();
    }

    constructor() {
        governance == msg.sender;
    }

    /// @inheritdoc IWithdrawalStack
    function addStrategy(address vault, address strategy) external onlyGovernance {
        // we assume the vault has checked what needs to be
        if (IYearn4626(vault).strategies(strategy).activation == 0) revert NotActive();

        // make sure we have room left
        if (withdrawalStack[vault].length >= MAX_WITHDRAWAL_STACK_SIZE) revert StackSize();

        // add strategy to the end of the array
        withdrawalStack[vault].push(strategy);

        emit StrategyAdded(vault, strategy);
    }

    /// @inheritdoc IWithdrawalStack
    function removeStrategy(address vault, address strategy) external {
        // allow for permisionless removal if the strategy has been revoked from the vault
        if (IYearn4626(vault).strategies(strategy).activation != 0) checkGovernance();

        address[] memory currentStack = withdrawalStack[vault];

        for (uint256 i; i < currentStack.length; ++i) {
            address _strategy = currentStack[i];
            if (_strategy == strategy) {
                if (i != currentStack.length - 1) {
                    // if it isn't the last strategy in the stack, move each strategy down one place
                    for(i; i < currentStack.length - 1; ++i) {
                        currentStack[i] = currentStack[i + 1];
                    }
                }

                // store the updated stack
                withdrawalStack[vault] = currentStack;
                // pop off the last item
                withdrawalStack[vault].pop();

                emit StrategyRemoved(vault, strategy);
                break;
            }
        }
    }

    /// @inheritdoc IWithdrawalStack
    function replaceWithdrawalStackIndex(
        address vault,
        uint256 idx,
        address newStrategy
    ) external onlyGovernance {
        if (IYearn4626(vault).strategies(newStrategy).activation == 0) revert NotActive();

        address oldStrategy = withdrawalStack[vault][idx];
        require(oldStrategy != newStrategy, "same strategy");

        withdrawalStack[vault][idx] = newStrategy;

        emit ReplacedWithdrawalStackIndex(vault, oldStrategy, newStrategy);
    }

    /// @inheritdoc IWithdrawalStack
    function setWithdrawalStack(address vault, address[] memory newStack) external onlyGovernance {
        if (newStack.length > MAX_WITHDRAWAL_STACK_SIZE) revert StackSize();

        IYearn4626 _vault = IYearn4626(vault);

        for (uint256 i; i < newStack.length; ++i) {
            if (_vault.strategies(newStack[i]).activation == 0) revert NotActive();
        }

        withdrawalStack[vault] = newStack;

        emit NewWithdrawStack(vault, newStack);
    }

    /// @inheritdoc IWithdrawalStack
    function getWithdrawalStack(address vault) public view returns (address[] memory) {
        return withdrawalStack[vault];
    }

    function setGovernance(address newGovernance) external onlyGovernance {
        pendingGovernance = newGovernance;
        emit NewPendingGovernance(newGovernance);
    }

    function acceptGovernance() external {
        if (msg.sender != pendingGovernance) revert NotAuthorized();
        governance = msg.sender;
        emit UpdateGovernance(msg.sender);
        pendingGovernance = address(0);
    }
}
