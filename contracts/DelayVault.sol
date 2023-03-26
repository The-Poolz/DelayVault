// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "poolz-helper-v2/contracts/interfaces/ILockedDealV2.sol";
import "./DelayView.sol";

/// @title DelayVault core logic
/// @author The-Poolz contract team
contract DelayVault is DelayView {
    constructor() {
        // maxDelay is set to year by default
        MaxDelay = 365 days;
    }

    function CreateVault(
        address _token,
        uint256 _amount,
        uint256 _startDelay,
        uint256 _cliffDelay,
        uint256 _finishDelay
    )
        external
        whenNotPaused
        nonReentrant
        notZeroAddress(_token)
        isTokenActive(_token)
    {
        if (
            !(_startDelay <= MaxDelay &&
                _cliffDelay <= MaxDelay &&
                _finishDelay <= MaxDelay)
        ) {
            revert AboveMaxDelay(MaxDelay);
        }
        Vault storage vault = VaultMap[_token][msg.sender];
        if (
            !(// for the possibility of increasing only the time parameters
            _amount > 0 ||
                _startDelay > vault.StartDelay ||
                _cliffDelay > vault.CliffDelay ||
                _finishDelay > vault.FinishDelay)
        ) {
            revert VaultValueNotChanged(_token, msg.sender);
        }
        _DelayValidator(
            _token,
            _amount,
            _startDelay,
            _cliffDelay,
            _finishDelay,
            vault
        );
        vault.StartDelay = _startDelay;
        vault.CliffDelay = _cliffDelay;
        vault.FinishDelay = _finishDelay;
        Array.addIfNotExsist(TokenToUsers[_token], msg.sender);
        Array.addIfNotExsist(MyTokens[msg.sender], _token);
        if (_amount > 0) {
            vault.Amount += _amount;
            TransferInToken(_token, msg.sender, _amount);
        }
        emit VaultValueChanged(
            _token,
            msg.sender,
            vault.Amount,
            vault.StartDelay,
            vault.CliffDelay,
            vault.FinishDelay
        );
    }

    /** @dev Creates a new pool of tokens for a specified period or,
         if there is no Locked Deal address, sends tokens to the owner.
    */
    function Withdraw(
        address _token
    ) external nonReentrant isVaultNotEmpty(_token, msg.sender) {
        Vault storage vault = VaultMap[_token][msg.sender];
        uint256 startDelay = block.timestamp + vault.StartDelay;
        uint256 finishDelay = startDelay + vault.FinishDelay;
        uint256 cliffDelay = startDelay + vault.CliffDelay;
        uint256 lockAmount = vault.Amount;
        vault.Amount = 0;
        vault.FinishDelay = vault.CliffDelay = vault.StartDelay = 0;
        if (LockedDealAddress != address(0)) {
            ApproveAllowanceERC20(_token, LockedDealAddress, lockAmount);
            ILockedDealV2(LockedDealAddress).CreateNewPool(
                _token,
                startDelay,
                cliffDelay,
                finishDelay,
                lockAmount,
                msg.sender
            );
        } else {
            TransferToken(_token, msg.sender, lockAmount);
        }
        emit VaultValueChanged(
            _token,
            msg.sender,
            vault.Amount,
            vault.StartDelay,
            vault.CliffDelay,
            vault.FinishDelay
        );
    }

    /// @dev the user can approve the redemption of their tokens by the admin
    function approveTokenRedemption(address _token, bool _status) external {
        Allowance[_token][msg.sender] = _status;
        emit TokenRedemptionApproval(_token, msg.sender, _status);
    }
}
