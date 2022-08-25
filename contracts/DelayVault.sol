// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "poolz-helper-v2/contracts/ETHHelper.sol";
import "./VaultManageable.sol";
import "poolz-helper-v2/contracts/interfaces/ILockedDeal.sol";
import "poolz-helper-v2/contracts/Array.sol";

/// @title main DelayVault logic
/// @author The-Poolz contract team
contract DelayVault is VaultManageable, ERC20Helper {
    event NewVaultCreated(
        address Token,
        uint256 Amount,
        uint64 LockTime,
        address Owner
    );
    event LockedPeriodStarted(address Token, uint256 Amount, uint64 FinishTime);

    constructor() {
        MinDelay = 0 days;
        MaxDelay = 365 days;
    }

    modifier isVaultNotEmpty(address _token) {
        require(
            VaultMap[_token][msg.sender].Amount > 0,
            "Your vault is already empty!"
        );
        _;
    }

    modifier isTokenValid(address _Token) {
        require(isTokenWhiteListed(_Token), "Need Valid ERC20 Token");
        _;
    }

    function CreateVault(
        address _token,
        uint256 _amount,
        uint64 _lockTime
    ) public whenNotPaused isTokenValid(_token) {
        require(_token != address(0), "invalid token address");
        require(_amount > 0, "amount should be greater than zero");
        TransferInToken(_token, msg.sender, _amount);
        VaultMap[_token][msg.sender] = Vault(_amount, _lockTime);
        MyTokens[msg.sender].push(_token);
        emit NewVaultCreated(_token, _amount, _lockTime, msg.sender);
    }

    function Withdraw(address _token, uint256 _amount)
        public
        isVaultNotEmpty(_token)
        whenNotPaused
    {
        Vault storage vault = VaultMap[_token][msg.sender];
        require(
            VaultMap[_token][msg.sender].Amount >= _amount,
            "not enough amount in vault"
        );
        uint64 finishTime = uint64(block.timestamp) + vault.LockPeriod;
        ApproveAllowanceERC20(_token, LockedDealAddress, _amount);
        ILockedDeal(LockedDealAddress).CreateNewPool(
            _token,
            finishTime,
            _amount,
            msg.sender
        );
        VaultMap[_token][msg.sender].Amount -= _amount;
        emit LockedPeriodStarted(_token, vault.Amount, finishTime);
    }

    function GetAllMyTokens() public view returns (address[] memory) {
        return MyTokens[msg.sender];
    }

    function GetMyTokens() public view returns (address[] memory) {
        address[] storage allTokens = MyTokens[msg.sender];
        address[] memory tokens = new address[](allTokens.length);
        uint256 index;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (VaultMap[allTokens[i]][msg.sender].Amount > 0) {
                tokens[index++] = allTokens[i];
            }
        }
        return Array.KeepNElementsInArray(tokens, index);
    }
}
