# DelayVault
[![Build Status](https://api.travis-ci.com/The-Poolz/DelayVault.svg?token=qArPwDxVjiye5pPqiscU&branch=master)](https://app.travis-ci.com/github/The-Poolz/DelayVault)
[![codecov](https://codecov.io/gh/The-Poolz/DelayVault/branch/master/graph/badge.svg)](https://codecov.io/gh/The-Poolz/DelayVault)
[![CodeFactor](https://www.codefactor.io/repository/github/the-poolz/DelayVault/badge)](https://www.codefactor.io/repository/github/the-poolz/DelayVault)

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
![classDiagram](https://user-images.githubusercontent.com/68740472/217502566-6827d515-761f-4542-880f-8d48817858b6.svg)

## Create new Vault
**Problem:**

To participate in IDO, need to lock tokens. There are usually pre-agreed conditions for participation, such as a minimum number of tokens and a locking time. After the lock time expires, the user may forget or physically be unable to re-lock the tokens for a longer period of time due to the restrictions of the [Locked-Pools](https://github.com/The-Poolz/Locked-pools) contract.

**Solution:**

Create a **Vault** that doesn't start the lock time before the start of the withdrawal.

https://github.com/The-Poolz/DelayVault/blob/a76a1825297a9126120ba47a83305f0a1287a9c9/contracts/DelayVault.sol#L12-L18

- **_token** - the address of the token that will be locked in vault.
- **_amount** - the number of tokens that will be in the vault, if there are already tokens in the vault, they will be summed up.
- **_startDelay** - the period of time that begins after withdrawal.
- **_cliffDelay** - time parameter that sets cliff for creating the pool. 
- **_finishDelay** - the time for which the tokens will be locked in the pool. 

## Start Lock Period
Creates a new pool of tokens for a specified period or, if there is no [Locked Deal address](https://github.com/The-Poolz/Locked-pools), sends tokens to the owner.
https://github.com/The-Poolz/DelayVault/blob/a76a1825297a9126120ba47a83305f0a1287a9c9/contracts/DelayVault.sol#L61

- **_token** - which token do you want to withdraw.

## Admin settings
#### Set Locked Deal address
`setLockedDealAddress` allows the admin to set the address of the **LockedDealV2** contract. Without a **Locked-Deal** address, the user will immediately receive their tokens upon withdrawal!
https://github.com/The-Poolz/DelayVault/blob/35eba8d1dc7ba9db7edbf39ad73441e05c58e78d/contracts/DelayManageable.sol#L12
- **_lockedDealAddress** - the new address of the Locked-Pools. Its default address is zero.

#### Setting Minimum Delays
The administrator can set the minimum delay time and the minimum number of blocked tokens. Each token limit can have its own minimum block time. When setting limits, they should be sorted from smallest to largest. 
https://github.com/The-Poolz/DelayVault/blob/35eba8d1dc7ba9db7edbf39ad73441e05c58e78d/contracts/DelayManageable.sol#L20-L26
If restrictions are set, the user will not be able to specify a lower value. The admin can specify his own minimum block time for a certain number of tokens.
- **_token** - the address of the token to which the blocking rules will apply.
- **_amounts** - array of quantitative limits of tokens.
- **_startDelays** - array of delay start limits. 
- **_cliffDelays** - array of output time limits in the pool.
- **_finishDelays** - array of pool end limits.

## License
The-Poolz Contracts is released under the MIT License.