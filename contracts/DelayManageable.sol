// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "poolz-helper-v2/contracts/GovManager.sol";
import "poolz-helper-v2/contracts/interfaces/IWhiteList.sol";
import "poolz-helper-v2/contracts/Array.sol";
import "./DelayModifiers.sol";
import "./DelayEvents.sol";

/// @title all admin settings
contract DelayManageable is Pausable, GovManager, DelayEvents, DelayModifiers {
    function setLockedDealAddress(address _lockedDealAddress)
        public
        onlyOwnerOrGov
        uniqueAddress(_lockedDealAddress, LockedDealAddress)
    {
        LockedDealAddress = _lockedDealAddress;
    }

    function setMinDelays(
        address _token,
        uint256[] memory _amounts,
        uint256[] memory _minDelays,
        uint256[] memory _cliffTimes
    ) public onlyOwnerOrGov notZeroAddress(_token) {
        require(_amounts.length == _minDelays.length, "invalid array length");
        require(Array.isArrayOrdered(_amounts), "amounts should be ordered");
        require(Array.isArrayOrdered(_minDelays), "delays should be sorted");
        DelayLimit[_token] = Delay(_amounts, _minDelays, _cliffTimes, true);
        emit UpdatedMinDelays(_token, _amounts, _minDelays, _cliffTimes);
    }

    function swapTokenStatusFilter(address _token)
        public
        onlyOwnerOrGov
        notZeroAddress(_token)
    {
        DelayLimit[_token].isActive = !DelayLimit[_token].isActive;
    }

    function Pause() public onlyOwnerOrGov {
        _pause();
    }

    function Unpause() public onlyOwnerOrGov {
        _unpause();
    }
}
