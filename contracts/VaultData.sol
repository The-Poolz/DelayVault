// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VaultManageable.sol";

/// @title VaultData - getter view functions
contract VaultData is VaultManageable {
    function GetAllMyTokens() public view returns (address[] memory) {
        return MyTokens[msg.sender];
    }

    function GetMyTokens() public view returns (address[] memory) {
        address[] storage allTokens = MyTokens[msg.sender];
        address[] memory tokens = new address[](allTokens.length);
        uint256 index;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (VaultMap[allTokens[i]][msg.sender].Amount > 0) {
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
        Delay storage delay = DelayLimit[_token];
        if (delay.Amounts.length == 0) {
            return type(uint256).max;
        } else if (delay.Amounts[0] > _amount) {
            return 0;
        }
        uint256 tempAmount = 0;
        _delay = delay.MinDelays[0];
        for (uint256 i = 0; i < delay.Amounts.length; i++) {
            if (
                _amount > delay.Amounts[i] &&
                tempAmount < delay.Amounts[i]
            ) {
                _delay = delay.MinDelays[i];
                tempAmount = delay.Amounts[i];
            }
        }
    }
}
