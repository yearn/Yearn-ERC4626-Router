// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/// @title Withdrawal Stack Contract for YearnV3 Router
abstract contract WithdrawalStack {

    address public governance;
    address public pendingGovernance;

    uint256 constant MAX_WITHDRAWAL_STACK_SIZE = 10;

    mapping(address => address[]) public withdrawalStack;

    event NewPendingGovernance(
        address pendingGovernnace
    );

    event UpdateGovernance(
        address newGovernance
    );

    constructor() {
        governance == msg.sender;
    }
    
    function getWithdrawalStack(address vault) public view returns(address[] memory) {
        return withdrawalStack[vault];
    }

    function setGovernance(address newGovernance) external {
        require(msg.sender == governance, "!auth");
        emit NewPendingGovernance(newGovernance);
        pendingGovernance = newGovernance;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!auth");
        governance = msg.sender;
        emit UpdateGovernance(msg.sender);
        pendingGovernance = address(0);
    }
}