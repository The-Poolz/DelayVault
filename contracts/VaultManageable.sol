// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "poolz-helper-v2/contracts/GovManager.sol";
import "poolz-helper-v2/contracts/interfaces/IWhiteList.sol";
import "poolz-helper-v2/contracts/Array.sol";
import "./DelayModifiers.sol";
import "./DelayEvents.sol";

/// @title all admin settings
contract VaultManageable is Pausable, GovManager, DelayEvents, DelayModifiers {
    function setLockedDealAddress(address _lockedDealAddress)
        public
        onlyOwnerOrGov
        uniqueAddress(_lockedDealAddress, LockedDealAddress)
    {
        LockedDealAddress = _lockedDealAddress;
    }

    function setWhiteListAddress(address _whiteListAddr)
        public
        onlyOwnerOrGov
        uniqueAddress(_whiteListAddr, WhiteListAddress)
    {
        WhiteListAddress = _whiteListAddr;
    }

    function setWhiteListId(uint256 _id)
        public
        onlyOwnerOrGov
        uniqueValue(_id, WhiteListId)
    {
        WhiteListId = _id;
    }

    function isTokenWhiteListed(address _tokenAddress)
        public
        view
        returns (bool)
    {
        return
            WhiteListAddress == address(0) ||
            WhiteListId == 0 ||
            IWhiteList(WhiteListAddress).Check(_tokenAddress, WhiteListId) > 0;
    }

    function setMinDelays(
        uint256[] memory _amounts,
        uint256[] memory _minDelays
    ) public onlyOwnerOrGov {
        require(_amounts.length == _minDelays.length, "invalid array length");
        require(Array.isArrayOrdered(_amounts), "amounts should be ordered");
        require(Array.isArrayOrdered(_minDelays), "delays should be sorted");
        DelayLimit = Delay(_amounts, _minDelays);
        emit UpdatedMinDelays(_amounts, _minDelays);
    }

    function Pause() public onlyOwnerOrGov {
        _pause();
    }

    function Unpause() public onlyOwnerOrGov {
        _unpause();
    }
}
