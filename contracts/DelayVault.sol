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
    ) public whenNotPaused notZeroAddress(_token) isTokenActive(_token) {
        require(
            _lockTime >= GetMinDelay(_token, _amount),
            "minimum delay greater than lock time"
        );
        require(_amount > 0, "amount should be greater than zero");
        uint256 amount = _amount;
        if (VaultMap[_token].length == 0 || VaultId[msg.sender] == 0) {
            Vault memory vault = Vault(msg.sender, _amount, _lockTime);
            VaultMap[_token].push(vault);
        } else {
            Vault storage vault = VaultMap[_token][VaultId[msg.sender] - 1];
            require(
                _lockTime >= vault.LockPeriod,
                "can't set a shorter blocking period than the last one"
            );
            TransferInToken(_token, msg.sender, _amount);
            vault.User = msg.sender;
            amount = vault.Amount += _amount;
            vault.LockPeriod = _lockTime;
        }
        VaultId[msg.sender] = VaultMap[_token].length;
        MyTokens[msg.sender].push(_token);
        emit NewVaultCreated(_token, msg.sender, amount, _lockTime);
    }

    function Withdraw(address _token)
        public
        notZeroAddress(LockedDealAddress)
        isVaultNotEmpty(_token)
    {
        Vault storage vault = VaultMap[_token][VaultId[msg.sender] - 1];
        uint256 startTime = block.timestamp + StartWithdrawals[_token];
        uint256 finishTime = block.timestamp + vault.LockPeriod;
        uint256 cliffTime = GetCliffTime(_token, vault.LockPeriod);
        uint256 lockAmount = vault.Amount;
        vault.Amount = 0;
        vault.LockPeriod = 0;
        ApproveAllowanceERC20(_token, LockedDealAddress, lockAmount);
        ILockedDealV2(LockedDealAddress).CreateNewPool(
            _token,
            startTime,
            cliffTime,
            finishTime,
            lockAmount,
            msg.sender
        );
        emit LockedPeriodStarted(_token, msg.sender, lockAmount, finishTime);
    }
}
