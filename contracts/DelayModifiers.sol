// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DelayData.sol";

/// @title contains modifiers and stores variables.
contract DelayModifiers is DelayData {
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

    modifier isTokenActive(address _token) {
        require(
            DelayLimit[_token].isActive,
            "there are no limits set for this token"
        );
        _;
    }

    modifier shortLockPeriod(address _token, uint256 _lockPeriod) {
        require(
            _lockPeriod >= VaultMap[_token][msg.sender].LockPeriod,
            "can't set a shorter blocking period than the last one"
        );
        _;
    }
}
