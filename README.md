# DelayVault
[![Build Status](https://api.travis-ci.com/The-Poolz/DelayVault.svg?token=qArPwDxVjiye5pPqiscU&branch=master)](https://app.travis-ci.com/github/The-Poolz/DelayVault)

Smart contract that **pre-locks** tokens indefinitely by creating **Vault**. When the **Vault** is closed by withdrawing tokens, a **Pool** is created for the specified period using a [Locked-Deal](https://github.com/The-Poolz/Locked-pools) contract.

### Navigation

- [Installation](#installation)
- [Contract relations](#uml)
- [Create new Vault](#create-new-vault)
- [Start Lock Period](#start-lock-period)
- [Admin settings](#admin-settings)
- [License](#license)
#### Installation

```console
npm install
```

#### Testing

```console
truffle run coverage
```

#### Deployment

```console
truffle dashboard
```

```console
truffle migrate --network dashboard
```
## UML
![classDiagram](https://user-images.githubusercontent.com/68740472/204778278-98a68001-c4f7-441f-8b0e-dce1e9dcd60c.svg)

## Create new Vault
**Problem:**

To participate in IDO, need to lock tokens. There are usually pre-agreed conditions for participation, such as a minimum number of tokens and a locking time. After the lock time expires, the user may forget or physically be unable to re-lock the tokens for a longer period of time due to the restrictions of the [Locked-Pools](https://github.com/The-Poolz/Locked-pools) contract.

**Solution:**

Create a **Vault** that doesn't start the lock time before the start of the withdrawal.

https://github.com/The-Poolz/DelayVault/blob/d9b48e048cc449492cc89586afe2420ba79b516c/contracts/DelayVault.sol#L12-L16

- **_token** - the address of the token that will be locked in vault.
- **_amount** - the number of tokens that will be in the vault, if there are already tokens in the vault, they will be summed up.
- **_lockTime** - the period of time that begins after withdrawal.

## Start Lock Period
Withdrawal creates a pool of locked tokens.
https://github.com/The-Poolz/DelayVault/blob/d9b48e048cc449492cc89586afe2420ba79b516c/contracts/DelayVault.sol#L37

- **_token** - which token do you want to withdraw.
- **_startWithdraw** - the variable time, which is added to the current time to determine the start time for blocking tokens.

## Admin settings
#### Set Locked Deal address
Without a Locked-Deal address, the user can't withdraw tokens from **Vault**.
https://github.com/The-Poolz/DelayVault/blob/d9b48e048cc449492cc89586afe2420ba79b516c/contracts/VaultManageable.sol#L13
- **_lockedDealAddress** - the new address of the Locked-Pools. Its default address is zero.

#### Setting Minimum Delays
Admin can set delays for each token. Each token limit can have its own minimum lock time. When setting limits, they should be sorted from smallest to largest.
https://github.com/The-Poolz/DelayVault/blob/d9b48e048cc449492cc89586afe2420ba79b516c/contracts/VaultManageable.sol#L21-L25
- **_token** - the address of the token to which the blocking rules will apply.
- **_amounts** - array of quantitative limits of tokens.
- **_delays** - an array of delay limits for each token limit.

## License
The-Poolz Contracts is released under the MIT License.