// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DelayData.sol";
import "poolz-helper-v2/contracts/Array.sol";

/// @title contains modifiers.
contract DelayModifiers is DelayData {
    modifier uniqueAddress(address _addr, address _oldAddr) {
        require(_addr != _oldAddr, "can't set the same address");
        _;
    }

    modifier uniqueValue(uint256 _value, uint256 _oldValue) {
        require(_value != _oldValue, "can't set the same value");
        _;
    }

    modifier notZeroAddress(address _addr) {
        _notZeroAddress(_addr);
        _;
    }

    modifier isVaultNotEmpty(address _token, address _owner) {
        require(VaultMap[_token][_owner].Amount > 0, "vault is already empty");
        _;
    }

    modifier validAmount(uint256 _fAmount, uint256 _sAmount) {
        require(_fAmount >= _sAmount, "invalid amount");
        _;
    }

    ///@dev By default, each token is inactive
    modifier isTokenActive(address _token) {
        require(
            DelayLimit[_token].isActive,
            "there are no limits set for this token"
        );
        _;
    }

    /// @dev the user can't set a time parameter less than the last one
    modifier validatetDelays(
        address _token,
        uint256 _startDelay,
        uint256 _cliffDelay,
        uint256 _finishDelay
    ) {
        {
        require(
            _startDelay >= VaultMap[_token][msg.sender].StartDelay,
            "can't set a shorter start period than the last one"
        );
        require(
            _cliffDelay >= VaultMap[_token][msg.sender].CliffDelay,
            "can't set a shorter cliff period than the last one"
        );
        require(
            _finishDelay >= VaultMap[_token][msg.sender].FinishDelay,
            "can't set a shorter finish period than the last one"
        );
        }
        _;
    }

    modifier orderedArray(uint256[] memory _array) {
        require(Array.isArrayOrdered(_array), "array should be ordered");
        _;
    }

    function _notZeroAddress(address _addr) private pure {
        require(_addr != address(0), "address can't be null");
    }

    function _equalValue(uint256 _fLength, uint256 _sLength) internal pure {
        require(_fLength == _sLength, "invalid array length");
    }

    function _checkMinDelay(uint256 _delay, uint256 _minDelay) internal pure {
        require(_delay >= _minDelay, "delay less than min delay");
    }
}
