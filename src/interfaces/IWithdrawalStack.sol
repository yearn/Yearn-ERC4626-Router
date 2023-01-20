// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

interface IWithdrawalStack {
    /************************** Events **************************/

    /// @notice 'strategy' has been added to the withdrawal stack for 'vault'
    event StrategyAdded(address indexed vault, address indexed strategy);

    /// @notice 'strategy' has been removed from the withdrawal stack for 'vault'
    event StrategyRemoved(address indexed vault, address indexed Strategy);

    /// @notice the withdrawal stack for 'vault' was replaced with 'stack'
    event NewWithdrawStack(address indexed vault, address[] indexed stack);

    /// @notice 'oldStategy' in withdrawal stack for 'vault' was replaced with 'newStrategy'
    event ReplacedWithdrawalStackIndex(address vualt, address indexed oldStrategy, address indexed newStrategy);

    /// @notice 'pendingGovernance' was set to be the next governance
    event NewPendingGovernance(address indexed pendingGovernnace);

    /// @notice 'newGovernance' accepted the role as the new governance
    event UpdateGovernance(address indexed newGovernance);

    /************************** Errors **************************/

    /// @notice Throw when a non-governance address calls permisioned functions
    error NotAuthorized();

    /// @notice Throw when trying to add a strategy that isnt activated in the Vault
    error NotActive();

    /// @notice Throw when adding to a withdrawal stack that is full or setting a stack.length > max
    error StackSize();
}