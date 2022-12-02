// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title contains all events.
contract DelayEvents {
    event NewVaultCreated(
        address indexed Token,
        address indexed Owner,
        uint256 Amount,
        uint256 LockTime
    );
    event LockedPeriodStarted(
        address indexed Token,
        address indexed Owner,
        uint256 Amount,
        uint256 FinishTime
    );
    event UpdatedMinDelays(
        address indexed Token,
        uint256[] Amounts,
        uint256[] MinDelays
    );
}
