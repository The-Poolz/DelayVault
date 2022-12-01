// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title contains modifiers and stores variables.
contract DelayModifiers {
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
    }

    modifier uniqueValue(uint256 _value, uint256 _oldValue) {
        require(_value != _oldValue, "can't set the same value");
        _;
    }

    modifier uniqueAddress(address _addr, address _oldAddr) {
        require(_addr != _oldAddr, "can't set the same address");
        _;
    }

    modifier notZeroAddress(address _addr) {
        require(_addr != address(0), "address can't be null");
        _;
    }

    modifier isVaultNotEmpty(address _token) {
        require(
            VaultMap[_token][msg.sender].Amount > 0,
            "vault is already empty"
        );
        _;
    }
}
