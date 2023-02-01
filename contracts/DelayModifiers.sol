// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DelayData.sol";
import "poolz-helper-v2/contracts/Array.sol";

/// @title contains modifiers and stores variables.
contract DelayModifiers is DelayData {
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

    modifier shortStartDelay(address _token, uint256 _startDelay) {
        require(
            _startDelay >= VaultMap[_token][msg.sender].StartDelay,
            "can't set a shorter start period than the last one"
        );
        _;
    }

    modifier shortFinishDelay(address _token, uint256 _finishDelay) {
        require(
            _finishDelay >= VaultMap[_token][msg.sender].FinishDelay,
            "can't set a shorter finish period than the last one"
        );
        _;
    }

    modifier equalValue(uint256 _fLength, uint256 _sLength) {
        require(_fLength == _sLength, "invalid array length");
        _;
    }

    modifier orderedArray(uint256[] memory _array) {
        require(Array.isArrayOrdered(_array), "array should be ordered");
        _;
    }
}
