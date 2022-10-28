// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "poolz-helper-v2/contracts/GovManager.sol";
import "poolz-helper-v2/contracts/interfaces/IWhiteList.sol";
import "poolz-helper-v2/contracts/Array.sol";

/// @title all admin settings
contract VaultManageable is Pausable, GovManager {
    address public LockedDealAddress;
    mapping(address => Delay) DelayLimit; // delay limit for every token
    mapping(address => address[]) public MyTokens;
    mapping(address => mapping(address => Vault)) public VaultMap;

    struct Vault {
        uint256 Amount;
        uint256 LockPeriod;
    }

    struct Delay {
        uint256[] Amounts;
        uint256[] MinDelays;
    }

    event UpdatedMinDelays(address Token, uint256[] Amounts, uint256[] MinDelays);

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
        uint256[] memory _minDelays
    ) public onlyOwnerOrGov {
        require(_amounts.length == _minDelays.length, "invalid array length");
        require(Array.isArrayOrdered(_amounts), "amounts should be ordered");
        require(Array.isArrayOrdered(_minDelays), "delays should be sorted");
        DelayLimit[_token] = Delay(_amounts, _minDelays);
        emit UpdatedMinDelays(_token, _amounts, _minDelays);
    }

    function Pause() public onlyOwnerOrGov {
        _pause();
    }

    function Unpause() public onlyOwnerOrGov {
        _unpause();
    }
}
