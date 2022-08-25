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

    function GetTokenLimits()
        public
        view
        returns (uint256[] memory _amount, uint256[] memory _minDelays)
    {
        return (TokenLimit.Amounts, TokenLimit.MinDelays);
    }

    function GetMinDelay(uint256 _amount) public view returns (uint256 _delay) {
        if (TokenLimit.Amounts.length == 0 || TokenLimit.Amounts[0] > _amount)
            return 0;
        uint256 tempAmount = 0;
        _delay = TokenLimit.MinDelays[0];
        for (uint256 i = 0; i < TokenLimit.Amounts.length; i++) {
            if (
                _amount > TokenLimit.Amounts[i] &&
                tempAmount < TokenLimit.Amounts[i]
            ) {
                _delay = TokenLimit.MinDelays[i];
                tempAmount = TokenLimit.Amounts[i];
            }
        }
    }
}
