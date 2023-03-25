// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "poolz-helper-v2/contracts/interfaces/ILockedDealV2.sol";
import "./DelayView.sol";

/// @title DelayVault core logic
/// @author The-Poolz contract team
contract DelayVault is DelayView {
    constructor() {
        // maxDelay are unlimited by default
        MaxDelay = type(uint256).max;
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
        _shortDelay(_token, _startDelay, _cliffDelay, _finishDelay); // Stack Too deep error fixing
        Vault storage vault = VaultMap[_token][msg.sender];
        require(
            _startDelay <= MaxDelay &&
                _cliffDelay <= MaxDelay &&
                _finishDelay <= MaxDelay,
            "Delay greater than Allowed"
        );
        require( // for the possibility of increasing only the time parameters
            _amount > 0 ||
                _startDelay > vault.StartDelay ||
                _cliffDelay > vault.CliffDelay ||
                _finishDelay > vault.FinishDelay,
            "Invalid parameters: increase at least one value"
        );
        (
            uint256 _startMinDelay,
            uint256 _cliffMinDelay,
            uint256 _finishMinDelay
        ) = _getMinDelays(_token, vault.Amount + _amount);
        // Checking the minimum delay for each timing parameter.
        _checkMinDelay(_startDelay, _startMinDelay);
        _checkMinDelay(_cliffDelay, _cliffMinDelay);
        _checkMinDelay(_finishDelay, _finishMinDelay);
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
    function SwapBuyBackStatus(address _token) external {
        Allowance[_token][msg.sender] = !Allowance[_token][msg.sender];
    }

    /// @dev the user can't set a time parameter less than the last one
    function _shortDelay(
        address _token,
        uint256 _startDelay,
        uint256 _cliffDelay,
        uint256 _finishDelay
    ) private view {
        _shortStartDelay(_token, _startDelay);
        _shortCliffDelay(_token, _cliffDelay);
        _shortFinishDelay(_token, _finishDelay);
    }
}
