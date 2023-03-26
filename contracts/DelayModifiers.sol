// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./DelayData.sol";
import "poolz-helper-v2/contracts/Array.sol";
import "./IDelayEvents.sol";

/// @title contains modifiers.
contract DelayModifiers is DelayData, IDelayEvents {
    modifier uniqueAddress(address _addr, address _oldAddr) {
        if (_addr == _oldAddr) {
            revert AddressNotChanged(_addr, _oldAddr);
        }
        _;
    }

    modifier uniqueValue(uint256 _value, uint256 _oldValue) {
        if (_value == _oldValue) {
            revert ValueNotChanged(_value, _oldValue);
        }
        _;
    }

    modifier notZeroAddress(address _addr) {
        if (_addr == address(0)) {
            revert NullAddress();
        }
        _;
    }

    modifier isVaultNotEmpty(address _token, address _owner) {
        if (VaultMap[_token][_owner].Amount == 0) {
            revert EmptyVault(_token, _owner);
        }
        _;
    }

    modifier validAmount(uint256 _fAmount, uint256 _sAmount) {
        if (_fAmount < _sAmount) {
            revert InvalidAmount(_fAmount, _sAmount);
        }
        _;
    }

    ///@dev By default, each token is inactive
    modifier isTokenActive(address _token) {
        if (!DelayLimit[_token].isActive) {
            revert InactiveToken(_token);
        }
        _;
    }

    modifier orderedArray(uint256[] memory _array) {
        if (!Array.isArrayOrdered(_array)) {
            revert NotOrderedArray(_array);
        }
        _;
    }

    modifier ValidatePaging(
        uint256 _from,
        uint256 _to,
        uint256 _max
    ) {
        if (_from > _to || _from > _max || _to > _max) {
            revert OutOfBound(_from, _to, _max);
        }
        _;
    }

    function _EqualValuesValidator(
        uint256 _amountsL,
        uint256 _startDelaysL,
        uint256 _finishDelaysL,
        uint256 _cliffDelaysL
    ) internal pure {
        if (
            _amountsL != _startDelaysL ||
            _finishDelaysL != _startDelaysL ||
            _cliffDelaysL != _startDelaysL
        ) {
            revert VauleNotEqual();
        }
    }

    function _DelayValidator(
        address _token,
        uint256 _amount,
        uint256 _startDelay,
        uint256 _cliffDelay,
        uint256 _finishDelay,
        Vault storage _vault
    ) internal view {
        (
            uint256 _startMinDelay,
            uint256 _cliffMinDelay,
            uint256 _finishMinDelay
        ) = _getMinDelays(_token, _vault.Amount + _amount);
        if (
            !(_startDelay >= _vault.StartDelay &&
                _cliffDelay >= _vault.CliffDelay &&
                _finishDelay >= _vault.FinishDelay &&
                _startDelay >= _startMinDelay &&
                _cliffDelay >= _cliffMinDelay &&
                _finishDelay >= _finishMinDelay)
        ) {
            revert InvalidDelayParameters();
        }
    }
}
