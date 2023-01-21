// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DelayManageable.sol";

/// @title DelayView - getter view functions
contract DelayView is DelayManageable {
    function GetAllUsersData(address _token)
        public
        view
        returns (address[] memory, Vault[] memory _vaults)
    {
        _vaults = new Vault[](Users[_token].length);
        for (uint256 i = 0; i < Users[_token].length; i++) {
            _vaults[i] = VaultMap[_token][Users[_token][i]];
        }
        return (Users[_token], _vaults);
    }

    function GetAllMyTokens(address _user)
        public
        view
        returns (address[] memory)
    {
        return MyTokens[_user];
    }

    function GetMyTokens(address _user) public view returns (address[] memory) {
        address[] storage allTokens = MyTokens[_user];
        address[] memory tokens = new address[](allTokens.length);
        uint256 index;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (VaultMap[allTokens[i]][_user].Amount > 0) {
                tokens[index++] = allTokens[i];
            }
        }
        return Array.KeepNElementsInArray(tokens, index);
    }

    function GetDelayLimits(address _token)
        public
        view
        returns (uint256[] memory _amount, uint256[] memory _minDelays)
    {
        return (DelayLimit[_token].Amounts, DelayLimit[_token].MinDelays);
    }

    function GetMinDelay(address _token, uint256 _amount)
        public
        view
        returns (uint256 _delay)
    {
        if (
            DelayLimit[_token].Amounts.length == 0 ||
            DelayLimit[_token].Amounts[0] > _amount
        ) return 0;
        uint256 tempAmount = 0;
        _delay = DelayLimit[_token].MinDelays[0];
        for (uint256 i = 0; i < DelayLimit[_token].Amounts.length; i++) {
            if (
                _amount >= DelayLimit[_token].Amounts[i] &&
                tempAmount < DelayLimit[_token].Amounts[i]
            ) {
                _delay = DelayLimit[_token].MinDelays[i];
                tempAmount = DelayLimit[_token].Amounts[i];
            }
        }
    }

    function GetCliffTime(address _token, uint256 _delay)
        public
        view
        returns (uint256 _cliffTime)
    {
        if (DelayLimit[_token].MinDelays[0] > _delay) return 0;
        uint256 tempDelay = 0;
        _cliffTime = DelayLimit[_token].CliffTimes[0];
        for (uint256 i = 0; i < DelayLimit[_token].Amounts.length; i++) {
            if (
                _delay >= DelayLimit[_token].MinDelays[i] &&
                tempDelay < DelayLimit[_token].MinDelays[i]
            ) {
                _cliffTime = DelayLimit[_token].CliffTimes[i];
                tempDelay = DelayLimit[_token].MinDelays[i];
            }
        }
    }
}
