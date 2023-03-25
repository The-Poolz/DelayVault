// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title contain stores variables.
contract DelayData {
    address public LockedDealAddress;
    mapping(address => Delay) public DelayLimit; // delay limit for every token
    mapping(address => mapping(address => Vault)) public VaultMap;
    mapping(address => mapping(address => bool)) public Allowance;
    mapping(address => address[]) public MyTokens;
    mapping(address => address[]) public TokenToUsers;
    uint256 public MaxDelay;

    struct Vault {
        uint256 Amount;
        uint256 StartDelay;
        uint256 CliffDelay;
        uint256 FinishDelay;
    }

    struct Delay {
        uint256[] Amounts;
        uint256[] StartDelays;
        uint256[] CliffDelays;
        uint256[] FinishDelays;
        bool isActive;
    }

    function _getMinDelays(
        address _token,
        uint256 _amount
    )
        internal
        view
        returns (uint256 _startDelay, uint256 _cliffDelay, uint256 _finishDelay)
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
}
