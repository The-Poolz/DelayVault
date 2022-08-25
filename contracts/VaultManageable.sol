// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "poolz-helper-v2/contracts/GovManager.sol";
import "poolz-helper-v2/contracts/interfaces/IWhiteList.sol";

/// @title all admin settings
contract VaultManageable is Pausable, GovManager {
    address public LockedDealAddress;
    address public WhiteListAddress;
    uint256 public WhiteListId;
    bool public isTokenFilterOn;
    uint256 public MaxDelay;
    uint256 public MinDelay;
    mapping(address => address[]) MyTokens;
    mapping(address => mapping(address => Vault)) VaultMap;

    struct Vault {
        uint256 Amount;
        uint64 LockPeriod;
    }

    modifier uniqueValue(uint256 _value, uint256 _oldValue) {
        require(_value != _oldValue, "can't set the same value");
        _;
    }

    modifier uniqueAddress(address _addr, address _oldAddr) {
        require(_addr != _oldAddr, "can't set the same address");
        _;
    }

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

    function swapTokenFilter() public onlyOwnerOrGov {
        isTokenFilterOn = !isTokenFilterOn;
    }

    function isTokenWhiteListed(address _tokenAddress)
        public
        view
        returns (bool)
    {
        return
            !isTokenFilterOn ||
            IWhiteList(WhiteListAddress).Check(_tokenAddress, WhiteListId) > 0;
    }

    function setMaxDelay(uint256 _maxDelay)
        public
        onlyOwnerOrGov
        uniqueValue(_maxDelay, MaxDelay)
    {
        require(
            _maxDelay >= MinDelay,
            "the maximum delay can't be less than the minimum delay!"
        );
        MaxDelay = _maxDelay;
    }

    function setMinDelay(uint256 _minDelay)
        public
        onlyOwnerOrGov
        uniqueValue(_minDelay, MinDelay)
    {
        require(
            _minDelay <= MaxDelay,
            "the minimum delay can't be greater than the maximum delay!"
        );
        MinDelay = _minDelay;
    }

    function Pause() public onlyOwnerOrGov {
        _pause();
    }

    function Unpause() public onlyOwnerOrGov {
        _unpause();
    }
}
