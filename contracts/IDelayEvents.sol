// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title contains all events.
interface IDelayEvents {
    event VaultValueChanged(
        address indexed Token,
        address indexed Owner,
        uint256 Amount,
        uint256 StartDelay,
        uint256 CliffDelay,
        uint256 FinishDelay
    );
    event UpdatedMinDelays(
        address indexed Token,
        uint256[] Amounts,
        uint256[] StartDelays,
        uint256[] CliffDelays,
        uint256[] FinishDelays
    );
    event UpdatedMaxDelay(uint256 OldDelay, uint256 NewDelay);
    event TokenRedemptionApproval(
        address indexed Token,
        address indexed User,
        bool Status
    );
    event RedeemedTokens(
        address indexed Token,
        uint256 Amount,
        uint256 RemaningAmount
    );
    event TokenStatusFilter(address indexed Token, bool Status);
    error AddressNotChanged(address _addr, address _oldAddr);
    error ValueNotChanged(uint256 _value, uint256 _oldValue);
    error EmptyVault(address _token, address _owner);
    error VaultValueNotChanged(address _token, address _owner);
    error InvalidAmount(uint256 _fAmount, uint256 _sAmount);
    error OutOfBound(uint256 _from, uint256 _to, uint256 _max);
    error PermissionNotGranted(address _token, address _owner);
    error VauleNotEqual();
    error InactiveToken(address _token);
    error NotOrderedArray(uint256[] _array);
    error NullAddress();
    error InvalidDelayParameters();
    error AboveMaxDelay(uint256 MaxDelay);
}
