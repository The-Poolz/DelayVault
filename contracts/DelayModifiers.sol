// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

    modifier orderedArray(uint256[] memory _array) {
        require(Array.isArrayOrdered(_array), "array should be ordered");
        _;
    }

    /// @dev the user can't set a time parameter less than the last one
    function _DelayValidator(
        address _token,
        uint256 _amount,
        uint256 _startDelay,
        uint256 _cliffDelay,
        uint256 _finishDelay,
        Vault storage _vault
    ) internal view {
        require(
            _startDelay >= _vault.StartDelay,
            "can't set a shorter start period than the last one"
        );
        require(
            _cliffDelay >= _vault.CliffDelay,
            "can't set a shorter cliff period than the last one"
        );
        require(
            _finishDelay >= _vault.FinishDelay,
            "can't set a shorter finish period than the last one"
        );
        (
            uint256 _startMinDelay,
            uint256 _cliffMinDelay,
            uint256 _finishMinDelay
        ) = _getMinDelays(_token, _vault.Amount + _amount);
        // Checking the minimum delay for each timing parameter.
        _checkMinDelay(_startDelay, _startMinDelay);
        _checkMinDelay(_cliffDelay, _cliffMinDelay);
        _checkMinDelay(_finishDelay, _finishMinDelay);
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
