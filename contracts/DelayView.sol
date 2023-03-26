// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./DelayManageable.sol";

/// @title DelayView - getter view functions
contract DelayView is DelayManageable {
    function GetUsersDataByRange(
        address _token,
        uint256 _from,
        uint256 _to
    ) external ValidatePaging(_from, _to, TokenToUsers[_token].length) view returns (address[] memory _users, Vault[] memory _vaults) {
        _vaults = new Vault[](_to - _from + 1);
        _users = new address[](_to - _from + 1);
        for (uint256 i = _from; i <= _to; i++) {
            _users[i] = TokenToUsers[_token][i];
            _vaults[i] = VaultMap[_token][TokenToUsers[_token][i]];
        }
    }

    function GetMyTokensByRange(
        address _user,
        uint256 _from,
        uint256 _to
    ) external ValidatePaging(_from, _to, MyTokens[_user].length) view returns (address[] memory _tokens) {
        _tokens = new address[](_to - _from + 1);
        for (uint256 i = _from; i <= _to; i++) {
            _tokens[i] = MyTokens[_user][i];
        }
    }

    function GetUsersLengthByToken(
        address _token
    ) external view returns (uint256) {
        return TokenToUsers[_token].length;
    }

    function GetMyTokensLengthByUser(
        address _user
    ) external view returns (uint256) {
        return MyTokens[_user].length;
    }

    function GetMyTokens(
        address _user
    ) external view returns (address[] memory tokens) {
        address[] memory allTokens = MyTokens[_user];
        tokens = new address[](allTokens.length);
        uint256 index = 0;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (VaultMap[allTokens[i]][_user].Amount > 0) {
                tokens[index++] = allTokens[i];
            }
        }
        // Resize the array to remove the empty slots
        assembly {
            mstore(tokens, index)
        }
    }

    function GetDelayLimits(
        address _token
    ) external view returns (Delay memory) {
        return DelayLimit[_token];
    }

    function GetMinDelays(
        address _token,
        uint256 _amount
    )
        external
        view
        isTokenActive(_token)
        returns (uint256 _startDelay, uint256 _cliffDelay, uint256 _finishDelay)
    {
        return _getMinDelays(_token, _amount);
    }

    function GetTokenFilterStatus(address _token) external view returns (bool) {
        return DelayLimit[_token].isActive;
    }

    function getChecksum() public view returns (bytes32) {
        return keccak256(abi.encodePacked(owner(), GovernorContract));
    }
}
