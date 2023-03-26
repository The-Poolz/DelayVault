// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/security/Pausable.sol";
import "poolz-helper-v2/contracts/GovManager.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "./DelayModifiers.sol";
import "./IDelayEvents.sol";

/// @title all admin settings
contract DelayManageable is
    Pausable,
    GovManager,
    IDelayEvents,
    DelayModifiers,
    ERC20Helper,
    ReentrancyGuard
{
    function setLockedDealAddress(
        address _lockedDealAddress
    )
        external
        onlyOwnerOrGov
        uniqueAddress(_lockedDealAddress, LockedDealAddress)
    {
        LockedDealAddress = _lockedDealAddress;
    }

    function setMinDelays(
        address _token,
        uint256[] calldata _amounts,
        uint256[] calldata _startDelays,
        uint256[] calldata _cliffDelays,
        uint256[] calldata _finishDelays
    ) external onlyOwnerOrGov notZeroAddress(_token) orderedArray(_amounts) {
        _equalValues(
            _amounts.length,
            _startDelays.length,
            _cliffDelays.length,
            _finishDelays.length
        );
        // timestamps may not be sorted
        for (uint256 i = 0; i < _startDelays.length; i++) {
            require(
                _startDelays[i] <= MaxDelay &&
                    _cliffDelays[i] <= MaxDelay &&
                    _finishDelays[i] <= MaxDelay,
                "one of timestamp elements greater than the maximum delay"
            );
        }
        DelayLimit[_token] = Delay(
            _amounts,
            _startDelays,
            _cliffDelays,
            _finishDelays,
            true
        );
        emit UpdatedMinDelays(
            _token,
            _amounts,
            _startDelays,
            _cliffDelays,
            _finishDelays
        );
    }

    function setMaxDelay(
        uint256 _maxDelay
    ) external onlyOwnerOrGov uniqueValue(MaxDelay, _maxDelay) {
        uint256 oldDelay = MaxDelay;
        MaxDelay = _maxDelay;
        emit UpdatedMaxDelay(oldDelay, _maxDelay);
    }

    function setTokenStatusFilter(
        address _token,
        bool _status
    ) external onlyOwnerOrGov notZeroAddress(_token) {
        DelayLimit[_token].isActive = _status;
        emit TokenStatusFilter(_token, _status);
    }

    function Pause() external onlyOwnerOrGov {
        _pause();
    }

    function Unpause() external onlyOwnerOrGov {
        _unpause();
    }

    function _equalValues(
        uint256 _amountsL,
        uint256 _startDelaysL,
        uint256 _finishDelaysL,
        uint256 _cliffDelaysL
    ) private pure {
        _equalValue(_amountsL, _startDelaysL);
        _equalValue(_finishDelaysL, _startDelaysL);
        _equalValue(_cliffDelaysL, _startDelaysL);
    }

    /// @dev redemption of approved ERC-20 tokens from the contract
    function redeemTokensFromVault(
        address _token,
        address _owner,
        uint256 _amount
    )
        external
        onlyOwnerOrGov
        nonReentrant
        notZeroAddress(_token)
        isVaultNotEmpty(_token, _owner)
        validAmount(VaultMap[_token][_owner].Amount, _amount)
    {
        require(Allowance[_token][_owner], "permission not granted");
        Vault storage vault = VaultMap[_token][_owner];
        vault.Amount -= _amount;
        if (vault.Amount == 0)
            vault.FinishDelay = vault.CliffDelay = vault.StartDelay = 0; // if Amount is zero, refresh vault values
        TransferToken(_token, msg.sender, _amount);
        emit RedeemedTokens(_token, _amount, vault.Amount);
    }
}
