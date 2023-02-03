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
        returns (
            uint256[] memory _amount,
            uint256[] memory _startDelays,
            uint256[] memory _finishDelays
        )
    {
        (_amount, _startDelays, _finishDelays) = (
            DelayLimit[_token].Amounts,
            DelayLimit[_token].StartDelays,
            DelayLimit[_token].FinishDelays
        );
    }

    function GetMinDelays(address _token, uint256 _amount)
        public
        view
        returns (
            uint256 _startDelay,
            uint256 _cliffDelay,
            uint256 _finishDelay
        )
    {
        if (
            DelayLimit[_token].Amounts.length == 0 ||
            DelayLimit[_token].Amounts[0] > _amount
        ) return (0, 0, 0);
        uint256 tempAmount = 0;
        _startDelay = DelayLimit[_token].StartDelays[0];
        _cliffDelay = DelayLimit[_token].CliffDelays[0];
        _finishDelay = DelayLimit[_token].FinishDelays[0];
        for (uint256 i = 0; i < DelayLimit[_token].Amounts.length; i++) {
            if (
                _amount >= DelayLimit[_token].Amounts[i] &&
                tempAmount < DelayLimit[_token].Amounts[i]
            ) {
                _startDelay = DelayLimit[_token].StartDelays[i];
                _cliffDelay = DelayLimit[_token].CliffDelays[i];
                _finishDelay = DelayLimit[_token].FinishDelays[i];
                tempAmount = DelayLimit[_token].Amounts[i];
            }
        }
    }
}
