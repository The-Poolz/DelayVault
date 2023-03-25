// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title contains all events.
interface IDelayEvents {
    event VaultValueChanged(
        address indexed Token,
        address indexed Owner,
        uint256 Amount,
        uint256 StartDelay,
        uint256 CliffDelay,
        uint256 FinishDelay
    );
    event UpdatedMinDelays(
        address indexed Token,
        uint256[] Amounts,
        uint256[] StartDelays,
        uint256[] CliffDelays,
        uint256[] FinishDelays
    );
    event TokenRedemptionApproval(
        address indexed Token,
        address indexed User,
        bool Status
    );
    event RedeemedTokens(
        address indexed Token,
        uint256 Amount,
        uint256 RemaningAmount
    );
    event TokenStatusFilter(
        address indexed Token,
        bool Status
    );
}
