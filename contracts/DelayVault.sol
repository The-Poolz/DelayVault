// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "poolz-helper-v2/contracts/ETHHelper.sol";
import "poolz-helper-v2/contracts/interfaces/ILockedDealV2.sol";
import "./DelayView.sol";

/// @title DelayVault core logic
/// @author The-Poolz contract team
contract DelayVault is DelayView, ERC20Helper {
    function CreateVault(
        address _token,
        uint256 _amount,
        uint256 _startDelay,
        uint256 _finishDelay
    )
        public
        whenNotPaused
        notZeroAddress(_token)
        isTokenActive(_token)
        shortStartDelay(_token, _startDelay)
        shortFinishDelay(_token, _finishDelay)
    {
        Vault storage vault = VaultMap[_token][msg.sender];
        require(
            _amount > 0 ||
                _startDelay > vault.StartDelay ||
                _finishDelay > vault.FinishDelay,
            "amount should be greater than zero"
        );
        (uint256 _startMinDelay, uint256 _finishMinDelay) = GetMinDelays(
            _token,
            _amount
        );
        require(
            _startDelay >= _startMinDelay,
            "start delay greater than min start delay"
        );
        require(
            _finishDelay >= _finishMinDelay,
            "finish delay greater than min finish delay"
        );
        TransferInToken(_token, msg.sender, _amount);
        vault.Amount += _amount;
        vault.StartDelay = _startDelay;
        vault.FinishDelay = _finishDelay;
        if (!Array.isInArray(Users[_token], msg.sender)) {
            Users[_token].push(msg.sender);
        }
        MyTokens[msg.sender].push(_token);
        VaultMap[msg.sender][_token] = vault; // populate mapping in the reverse direction
        emit VaultValueChanged(
            _token,
            msg.sender,
            vault.Amount,
            _startDelay,
            _finishDelay
        );
    }

    /** @dev Creates a new pool of tokens for a specified period or,
         if there is no Locked Deal address, sends tokens to the owner.
    */
    function Withdraw(address _token) public isVaultNotEmpty(_token) {
        Vault storage vault = VaultMap[_token][msg.sender];
        uint256 startDelay = block.timestamp + vault.StartDelay;
        uint256 finishDelay = startDelay + vault.FinishDelay;
        uint256 lockAmount = vault.Amount;
        vault.Amount = vault.FinishDelay = vault.StartDelay = 0;
        if (LockedDealAddress != address(0)) {
            ApproveAllowanceERC20(_token, LockedDealAddress, lockAmount);
            ILockedDealV2(LockedDealAddress).CreateNewPool(
                _token,
                startDelay,
                0,
                finishDelay,
                lockAmount,
                msg.sender
            );
        } else {
            TransferToken(_token, msg.sender, lockAmount);
        }
        emit VaultValueChanged(_token, msg.sender, 0, 0, 0);
    }
}
