// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title contains all events.
contract DelayEvents {
    event NewVaultCreated(
        address Token,
        uint256 Amount,
        uint256 LockTime,
        address Owner
    );
    event LockedPeriodStarted(
        address Token,
        uint256 Amount,
        uint256 FinishTime,
        address Owner
    );
    event UpdatedMinDelays(
        address Token,
        uint256[] Amounts,
        uint256[] MinDelays
    );
}
