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

    function _DelayValidator(
        address _token,
        uint256 _amount,
        uint256 _startDelay,
        uint256 _cliffDelay,
        uint256 _finishDelay,
        Vault storage _vault
    ) internal view {
        // Ensure that the new start delay is greater than or equal to the previous start delay
        require(
            _startDelay >= _vault.StartDelay,
            "start delay less than previous start delay"
        );

        // Ensure that the new cliff delay is greater than or equal to the previous cliff delay
        require(
            _cliffDelay >= _vault.CliffDelay,
            "cliff delay less than previous cliff delay"
        );

        // Ensure that the new finish delay is greater than or equal to the previous finish delay
        require(
            _finishDelay >= _vault.FinishDelay,
            "finish delay less than previous finish delay"
        );

        // Get the minimum delays based on the new amount
        (
            uint256 _startMinDelay,
            uint256 _cliffMinDelay,
            uint256 _finishMinDelay
        ) = _getMinDelays(_token, _vault.Amount + _amount);

        // Ensure that the new start delay is greater than or equal to the minimum start delay
        require(
            _startDelay >= _startMinDelay,
            "start delay less than minimum start delay"
        );

        // Ensure that the new cliff delay is greater than or equal to the minimum cliff delay
        require(
            _cliffDelay >= _cliffMinDelay,
            "cliff delay less than minimum cliff delay"
        );

        // Ensure that the new finish delay is greater than or equal to the minimum finish delay
        require(
            _finishDelay >= _finishMinDelay,
            "finish delay less than minimum finish delay"
        );
    }

    function _notZeroAddress(address _addr) private pure {
        require(_addr != address(0), "address can't be null");
    }

    function _equalValue(uint256 _fLength, uint256 _sLength) internal pure {
        require(_fLength == _sLength, "invalid array length");
    }
}
