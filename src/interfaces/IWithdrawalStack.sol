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

    /************************** Main Functions **************************/

    /** 
     @notice Adds a new "strategy" to a specific "vault" withdrawal stack
     @param vault, Address of the vault to add the strategy to
     @param strategy, Address of the strategy to add to the vaults stack
     @dev Reverts if the withdrawal stack is already MAX_WITHDRAWAL_STACK_SIZE
    */
    function addStrategy(address vault, address strategy) external;

    /**
     @notice Removes a "strategy" from a specific "vault" withdrawal stack
     @param vault, Address of the vault to remove the strategy from
     @param strategy, Address of the strategy to remove from the vaults stack
     @dev Permisionless to remove strategies that have been revoked by the vault already
    */
    function removeStrategy(address vault, address strategy) external;

    /**
     @notice Replace a specific strategy with a new strategy
     @param vault, Address of the vault whose stack we are updating
     @param idx, The index where the old strategy is in the stack
     @param newStrategy, The address of the new strategy to replace the old one
    */
    function replaceWithdrawalStackIndex(
        address vault,
        uint256 idx,
        address newStrategy
    ) external;

    /**
     @notice Set the full withdrawal stack for a 'vault' at once
     @param vault, The address of the vaults whose stack we are setting
     @param newStack, Dynamic array of address' that will be set as the new stack
     @dev Will revert if the newStack.length > MAX_WITHDRAWAL_STACK_SIZE
     */
    function setWithdrawalStack(address vault, address[] memory newStack) external;

    /**
     @notice View function to return the full withdrawal stack for any 'vault
     @param vault, Address of the vault
     @return withdrawalStack array containing all the strategies currently in the withdrawal stack
    */
    function getWithdrawalStack(address vault) external view returns (address[] memory);
}
