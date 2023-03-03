// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "poolz-helper-v2/contracts/ERC20Helper.sol";
import "poolz-helper-v2/contracts/ETHHelper.sol";
import "poolz-helper-v2/contracts/interfaces/ILockedDealV2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./DelayView.sol";

/// @title DelayVault core logic
/// @author The-Poolz contract team
contract DelayVault is DelayView, ERC20Helper, ReentrancyGuard {
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
        require( // for the possibility of increasing only the time parameters
            _amount > 0 ||
                _startDelay > vault.StartDelay ||
                _cliffDelay > vault.CliffDelay ||
                _finishDelay > vault.FinishDelay,
            "amount should be greater than zero"
        );
        (
            uint256 _startMinDelay,
            uint256 _cliffMinDelay,
            uint256 _finishMinDelay
        ) = GetMinDelays(_token, _amount);
        {
            // Checking the minimum delay for each timing parameter.
            _checkMinDelay(_startDelay, _startMinDelay);
            _checkMinDelay(_cliffDelay, _cliffMinDelay);
            _checkMinDelay(_finishDelay, _finishMinDelay);
        }
        TransferInToken(_token, msg.sender, _amount);
        vault.StartDelay = _startDelay;
        vault.CliffDelay = _cliffDelay;
        vault.FinishDelay = _finishDelay;
        Array.addIfNotExsist(Users[_token], msg.sender);
        Array.addIfNotExsist(MyTokens[msg.sender], _token);
        emit VaultValueChanged(
            _token,
            msg.sender,
            vault.Amount += _amount,
            _startDelay,
            _cliffDelay,
            _finishDelay
        );
    }

    /** @dev Creates a new pool of tokens for a specified period or,
         if there is no Locked Deal address, sends tokens to the owner.
    */
    function Withdraw(address _token, uint256 _amount)
        external
        nonReentrant
        isVaultNotEmpty(_token, msg.sender)
        notZeroValue(_amount)
    {
        _withdraw(_token, msg.sender, msg.sender, _amount);
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

    function ApproveAllowance(
        address _token,
        address _spender,
        uint256 _amount
    ) public notZeroAddress(_token) notZeroAddress(_spender) {
        Allowance[_token][_spender] = _amount;
        emit VaultApproval(_token, _spender, _amount);
    }

    function WithdrawFrom(
        address _token,
        address _owner,
        address _spender,
        uint256 _amount
    )
        external
        isVaultNotEmpty(_token, _owner)
        notZeroAddress(_spender)
        notZeroValue(_amount)
        nonReentrant
    {
        require(
            Allowance[_token][_spender] > 0 &&
                Allowance[_token][_spender] >= _amount,
            "DelayVault: insufficient allowance"
        );
        _withdraw(_token, _owner, _spender, _amount);
        ApproveAllowance(_token, _spender, _amount);
    }

    function _withdraw(
        address _token,
        address _owner,
        address _to,
        uint256 _amount
    ) internal {
        Vault storage vault = VaultMap[_token][_owner];
        uint256 startDelay = block.timestamp + vault.StartDelay;
        uint256 finishDelay = startDelay + vault.FinishDelay;
        uint256 cliffDelay = startDelay + vault.CliffDelay;
        if ((vault.Amount -= _amount) == 0)
            vault.FinishDelay = vault.CliffDelay = vault.StartDelay = 0;
        if (LockedDealAddress != address(0)) {
            ApproveAllowanceERC20(_token, LockedDealAddress, _amount);
            ILockedDealV2(LockedDealAddress).CreateNewPool(
                _token,
                startDelay,
                cliffDelay,
                finishDelay,
                _amount,
                _to
            );
        } else {
            TransferToken(_token, _to, _amount);
        }
        emit VaultValueChanged(_token, _owner, vault.Amount, 0, 0, 0);
    }
}
