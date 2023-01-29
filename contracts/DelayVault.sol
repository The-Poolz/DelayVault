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
        uint256 _lockTime
    )
        public
        whenNotPaused
        notZeroAddress(_token)
        isTokenActive(_token)
        shortLockPeriod(_token, _lockTime)
    {
        Vault storage vault = VaultMap[_token][msg.sender];
        require(
            _amount > 0 || _lockTime > vault.LockPeriod,
            "amount should be greater than zero"
        );
        require(
            _lockTime >= GetMinDelay(_token, _amount),
            "minimum delay greater than lock time"
        );
        TransferInToken(_token, msg.sender, _amount);
        vault.Amount += _amount;
        vault.LockPeriod = _lockTime;
        if (!Array.isInArray(Users[_token], msg.sender)) {
            Users[_token].push(msg.sender);
        }
        MyTokens[msg.sender].push(_token);
        emit VaultValueChanged(_token, msg.sender, vault.Amount, _lockTime);
    }

    function Withdraw(address _token)
        public
        notZeroAddress(LockedDealAddress)
        isVaultNotEmpty(_token)
    {
        Vault storage vault = VaultMap[_token][msg.sender];
        uint256 finishTime = block.timestamp + vault.LockPeriod;
        uint256 cliffTime = GetCliffTime(_token, vault.LockPeriod);
        uint256 lockAmount = vault.Amount;
        vault.Amount = 0;
        vault.LockPeriod = 0;
        ApproveAllowanceERC20(_token, LockedDealAddress, lockAmount);
        ILockedDealV2(LockedDealAddress).CreateNewPool(
            _token,
            block.timestamp,
            cliffTime,
            finishTime,
            lockAmount,
            msg.sender
        );
        emit VaultValueChanged(_token, msg.sender, 0, 0);
    }
}
