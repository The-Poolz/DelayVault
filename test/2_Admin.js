const DelayVault = artifacts.require("DelayVault")
const TestToken = artifacts.require("ERC20Token")

const truffleAssert = require("truffle-assertions")
const { assert } = require("chai")

contract("Delay vault admin settings", (accounts) => {
    let instance, token
    const lockedDealAddr = accounts[8]
    const amount = 1000
    const day = 86400
    const week = day * 7
    const amounts = [amount, amount * 2, amount * 3]
    const startDelays = [0, 0, 0]
    const cliffDelays = [0, 0, 0]
    const finishDelays = [day, week, week * 2]

    before(async () => {
        instance = await DelayVault.new()
        token = await TestToken.new("TestToken", "TEST")
    })

    it("should pause contract", async () => {
        await instance.Pause()
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(instance.CreateVault(token.address, amount, 0, 0, week), "Pausable: paused")
        await instance.Unpause()
        await instance.CreateVault(token.address, amount, 0, 0, week)
    })

    it("should set LockedDeal", async () => {
        await instance.setLockedDealAddress(lockedDealAddr)
        const lockedDeal = await instance.LockedDealAddress()
        assert.equal(lockedDealAddr, lockedDeal.toString())
    })

    it("should set min delays", async () => {
        const twoDays = day * 2
        const threeDays = day * 3
        const amounts = [10, 20, 30]
        const startDelays = [day, twoDays, threeDays]
        const tx = await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        const resAmounts = tx.logs[0].args.Amounts
        const startDelArray = tx.logs[0].args.StartDelays
        const finishDelArray = tx.logs[0].args.FinishDelays
        const _token = tx.logs[0].args.Token
        assert.equal(amounts.toString(), resAmounts.toString())
        assert.equal(startDelays.toString(), startDelArray.toString())
        assert.equal(finishDelays.toString(), finishDelArray.toString())
        assert.equal(_token.toString(), token.address.toString())
    })

    it("should set max delay", async () => {
        const oldMaxDelay = await instance.MaxDelay()
        const maxDelay = 604800 // 1 week in seconds
        await instance.setMaxDelay(maxDelay)
        const newMaxDelay = await instance.MaxDelay()
        assert.equal(newMaxDelay.toString(), maxDelay.toString())
        await truffleAssert.reverts(instance.setMaxDelay(maxDelay), "can't set the same value")
        await truffleAssert.reverts(instance.setMaxDelay("0"), "max Delay can't be null")
        // bring back the old delay
        await instance.setMaxDelay(oldMaxDelay)
    })

    it("should revert arrays with dirrent lengths", async () => {
        const invaliFinishTimes = [day, week]
        await truffleAssert.reverts(
            instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, invaliFinishTimes),
            "invalid array length"
        )
        const invalidStartDelays = [day, week]
        await truffleAssert.reverts(
            instance.setMinDelays(token.address, amounts, invalidStartDelays, cliffDelays, finishDelays),
            "invalid array length"
        )
        const invalidAmounts = [10, 20, 30, 50]
        await truffleAssert.reverts(
            instance.setMinDelays(token.address, invalidAmounts, startDelays, cliffDelays, finishDelays),
            "invalid array length"
        )
        const invalidCliffDelays = [day, week]
        await truffleAssert.reverts(
            instance.setMinDelays(token.address, amounts, startDelays, invalidCliffDelays, finishDelays),
            "invalid array length"
        )
    })

    it("should revert with the same value", async () => {
        await truffleAssert.reverts(instance.setLockedDealAddress(lockedDealAddr), "can't set the same address")
    })

    it("should revert when no limits are set for this token", async () => {
        token = await TestToken.new("TestToken", "TEST")
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, 0, 0, week),
            "there are no limits set for this token"
        )
    })

    it("should deactivate/activate token", async () => {
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays) // isActive = true
        await token.approve(instance.address, amount)
        await instance.swapTokenStatusFilter(token.address) // isActive = false
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, week, week, week),
            "there are no limits set for this token"
        )
        await instance.swapTokenStatusFilter(token.address) // isActive = true
        await truffleAssert.passes(instance.CreateVault(token.address, amount, week, week, week))
    })

    it("buy back half tokens from vault", async () => {
        const token = await TestToken.new("TestToken", "TEST", { from: accounts[1] })
        const oldBal = await token.balanceOf(accounts[0])
        assert.equal(oldBal, 0)
        await token.approve(instance.address, amount, { from: accounts[1] })
        await instance.swapTokenStatusFilter(token.address)
        await instance.CreateVault(token.address, amount, week, week, week * 2, { from: accounts[1] })
        await truffleAssert.reverts(
            instance.BuyBackTokens(token.address, accounts[1], amount / 2),
            "permission not granted"
        )
        await truffleAssert.reverts(instance.BuyBackTokens(token.address, accounts[1], amount * 2), "invalid amount")
        // user approve the redemption of their tokens by the admin
        await instance.approveTokenRedemption(token.address, { from: accounts[1] })
        // buy back half tokens
        const tx = await instance.BuyBackTokens(token.address, accounts[1], amount / 2)
        // check events values
        assert.equal(tx.logs[tx.logs.length - 1].args.Token.toString(), token.address.toString())
        assert.equal(tx.logs[tx.logs.length - 1].args.Amount.toString(), amount / 2)
        assert.equal(tx.logs[tx.logs.length - 1].args.RemaningAmount.toString(), amount / 2)
        // check vault data
        const data = await instance.VaultMap(token.address, accounts[1])
        assert.equal(data.Amount, (amount / 2).toString())
        assert.equal(data.StartDelay, week.toString())
        assert.equal(data.CliffDelay, week.toString())
        assert.equal(data.FinishDelay, (week * 2).toString())
        // check current balance
        const bal = await token.balanceOf(accounts[0])
        assert.equal(bal, amount / 2)
        assert.notEqual(oldBal, bal)
    })

    it("Buy back all tokens from contract", async () => {
        const token = await TestToken.new("TestToken", "TEST", { from: accounts[1] })
        const oldBal = await token.balanceOf(accounts[0])
        assert.equal(oldBal, 0)
        await token.approve(instance.address, amount, { from: accounts[1] })
        await instance.swapTokenStatusFilter(token.address)
        await instance.CreateVault(token.address, amount, week, week, week * 2, { from: accounts[1] })
        await truffleAssert.reverts(
            instance.BuyBackTokens(token.address, accounts[1], amount),
            "permission not granted"
        )
        // user approve the redemption of their tokens by the admin
        await instance.approveTokenRedemption(token.address, { from: accounts[1] })
        // buy back half tokens
        const tx = await instance.BuyBackTokens(token.address, accounts[1], amount)
        // check events values
        assert.equal(tx.logs[tx.logs.length - 1].args.Token.toString(), token.address.toString())
        assert.equal(tx.logs[tx.logs.length - 1].args.Amount.toString(), amount)
        assert.equal(tx.logs[tx.logs.length - 1].args.RemaningAmount.toString(), 0)
        // check vault data
        const data = await instance.VaultMap(token.address, accounts[1])
        assert.equal(data.Amount, 0)
        assert.equal(data.StartDelay, 0)
        assert.equal(data.CliffDelay, 0)
        assert.equal(data.FinishDelay, 0)
        // check current balance
        const bal = await token.balanceOf(accounts[0])
        assert.equal(bal, amount)
        assert.notEqual(oldBal, bal)
    })
})
