// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "poolz-helper-v2/contracts/ETHHelper.sol";
import "./VaultManageable.sol";
import "poolz-helper-v2/contracts/interfaces/ILockedDeal.sol";

/// @title main DelayVault settings
/// @author The-Poolz contract team
contract DelayVault is VaultManageable, ERC20Helper {
    event NewVaultCreated(
        uint256 Id,
        address Token,
        uint256 Amount,
        uint64 LockTime,
        address Owner
    );
    event LockedPeriodStarted(
        uint256 Id,
        address Token,
        uint256 Amount,
        uint64 FinishTime
    );

    constructor() {
        MinDelay = 0 days;
        MaxDelay = 365 days;
    }

    modifier isVaultOwner(uint256 _VaultId) {
        require(
            VaultMap[_VaultId].Owner == msg.sender,
            "You are not Vault Owner"
        );
        _;
    }

    function CreateVault(
        address _token,
        uint256 _amount,
        uint64 _lockTime
    ) public whenNotPaused returns (uint256) {
        require(_token != address(0), "invalid token address");
        require(_amount > 0, "amount should be greater than zero");
        TransferInToken(_token, msg.sender, _amount);
        VaultMap[VaultId] = Vault(_token, _amount, _lockTime, msg.sender);
        emit NewVaultCreated(VaultId, _token, _amount, _lockTime, msg.sender);
        return VaultId++;
    }

    function Withdraw(uint256 _vaultId)
        public
        isVaultOwner(_vaultId)
        whenNotPaused
    {
        Vault storage vault = VaultMap[_vaultId];
        uint64 finishTime = uint64(block.timestamp) + vault.LockPeriod;
        ApproveAllowanceERC20(vault.Token, LockedDealAddress, vault.Amount);
        uint256 id = ILockedDeal(LockedDealAddress).CreateNewPool(
            vault.Token,
            finishTime,
            vault.Amount,
            msg.sender
        );
        emit LockedPeriodStarted(id, vault.Token, vault.Amount, finishTime);
    }
}
