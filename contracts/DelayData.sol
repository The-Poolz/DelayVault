// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title contain stores variables.
contract DelayData {
    address public LockedDealAddress;
    mapping(address => Delay) DelayLimit; // delay limit for every token
    mapping(address => address[]) public MyTokens;
    mapping(address => uint256) public StartWithdrawals;
    mapping(address => mapping(address => Vault)) public VaultMap;

    struct Vault {
        uint256 Amount;
        uint256 LockPeriod;
    }

    struct Delay {
        uint256[] Amounts;
        uint256[] MinDelays;
        bool isActive;
    }
}
