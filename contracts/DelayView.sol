// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./DelayManageable.sol";

/// @title DelayView - getter view functions
contract DelayView is DelayManageable {
    function GetUsersDataByRange(
        address _token,
        uint256 _from,
        uint256 _to
    ) external view returns (address[] memory _users, Vault[] memory _vaults) {
        require(_from <= _to, "_from index can't be greater than _to");
        require(
            _from < Users[_token].length && _to < Users[_token].length,
            "index out of range"
        );
        _vaults = new Vault[](_to - _from + 1);
        _users = new address[](_to - _from + 1);
        for (uint256 i = _from; i <= _to; i++) {
            _users[i] = Users[_token][i];
            _vaults[i] = VaultMap[_token][Users[_token][i]];
        }
    }

    function GetMyTokensByRange(
        address _user,
        uint256 _from,
        uint256 _to
    ) external view returns (address[] memory _tokens) {
        require(_from <= _to, "_from index can't be greater than _to");
        require(
            _from < MyTokens[_user].length && _to < MyTokens[_user].length,
            "index out of range"
        );
        _tokens = new address[](_to - _from + 1);
        for (uint256 i = _from; i <= _to; i++) {
            _tokens[i] = MyTokens[_user][i];
        }
    }

    function GetUsersLengthByToken(
        address _token
    ) external view returns (uint256) {
        return Users[_token].length;
    }

    function GetMyTokens(address _user)
        external
        view
        returns (address[] memory)
    {
        address[] memory allTokens = MyTokens[_user];
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
        external
        view
        returns (
            uint256[] memory _amount,
            uint256[] memory _startDelays,
            uint256[] memory _cliffDelays,
            uint256[] memory _finishDelays
        )
    {
        (_amount, _startDelays, _cliffDelays, _finishDelays) = (
            DelayLimit[_token].Amounts,
            DelayLimit[_token].StartDelays,
            DelayLimit[_token].CliffDelays,
            DelayLimit[_token].FinishDelays
        );
    }

    function GetMinDelays(address _token, uint256 _amount)
        external
        view
        isTokenActive(_token)
        returns (
            uint256 _startDelay,
            uint256 _cliffDelay,
            uint256 _finishDelay
        )
    {
           return _getMinDelays(_token, _amount);
    }

    function _getMinDelays(address _token, uint256 _amount)
        internal
        view      
        returns (
            uint256 _startDelay,
            uint256 _cliffDelay,
            uint256 _finishDelay
        )
    {
        Delay memory delayLimit = DelayLimit[_token];
        uint256 arrLength = delayLimit.Amounts.length;
        if (arrLength == 0 || delayLimit.Amounts[0] > _amount) return (0, 0, 0);
        _startDelay = delayLimit.StartDelays[0];
        _cliffDelay = delayLimit.CliffDelays[0];
        _finishDelay = delayLimit.FinishDelays[0];
        for (uint256 i = 1; i < arrLength; i++) {
            if (_amount >= delayLimit.Amounts[i]) {
                _startDelay = delayLimit.StartDelays[i];
                _cliffDelay = delayLimit.CliffDelays[i];
                _finishDelay = delayLimit.FinishDelays[i];
            } else {
                break;
            }
        }
    }

    function GetTokenFilterStatus(address _token) external view returns (bool) {
        return DelayLimit[_token].isActive;
    }
}
