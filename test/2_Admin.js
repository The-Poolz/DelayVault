const DelayVault = artifacts.require("DelayVault")
const TestToken = artifacts.require("ERC20Token")

const truffleAssert = require("truffle-assertions")
const { assert } = require("chai")

contract("Delay vault admin settings", (accounts) => {
    let instance, token
    const lockedDealAddr = accounts[8]
    const amount = 1000
    const day = 1 * 24 * 60 * 60
    const week = day * 7
    const amounts = [amount, amount * 2, amount * 3]
    const lockPeriods = [day, week, week * 2]

    before(async () => {
        instance = await DelayVault.new()
        token = await TestToken.new("TestToken", "TEST")
    })

    it("should pause contract", async () => {
        await instance.Pause()
        await instance.setMinDelays(token.address, amounts, lockPeriods)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(instance.CreateVault(token.address, amount, week), "Pausable: paused")
        await instance.Unpause()
        await instance.CreateVault(token.address, amount, week)
    })

    it("should set LockedDeal", async () => {
        await instance.setLockedDealAddress(lockedDealAddr)
        const lockedDeal = await instance.LockedDealAddress()
        assert.equal(lockedDealAddr, lockedDeal.toString())
    })

    it("should set min delay", async () => {
        const twoDays = day * 2
        const threeDays = day * 3
        const amounts = [10, 20, 30]
        const lockPeriods = [day, twoDays, threeDays]
        const tx = await instance.setMinDelays(token.address, amounts, lockPeriods)
        const resAmounts = tx.logs[0].args.Amounts
        const MinDelays = tx.logs[0].args.MinDelays
        const _token = tx.logs[0].args.Token
        assert.equal(amounts.toString(), resAmounts.toString())
        assert.equal(lockPeriods.toString(), MinDelays.toString())
        assert.equal(_token.toString(), token.address.toString())
        await truffleAssert.reverts(instance.setMinDelays(_token, amounts, [day, twoDays]), "invalid array length")
    })

    it("should set start withdraw", async () => {
        const oldStartWithdraw = await instance.StartWithdrawals(token.address)
        const newStartWithdraw = 3600
        await instance.setStartWithdraw(token.address, newStartWithdraw)
        const currentStartWithdraw = await instance.StartWithdrawals(token.address)
        assert.equal(currentStartWithdraw, newStartWithdraw)
        assert.notEqual(oldStartWithdraw, currentStartWithdraw)
    })

    it("should revert with the same value", async () => {
        await truffleAssert.reverts(instance.setLockedDealAddress(lockedDealAddr), "can't set the same address")
    })

    it("should revert when no limits are set for this token", async () => {
        token = await TestToken.new("TestToken", "TEST")
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(instance.CreateVault(token.address, amount, week), "there are no limits set for this token")
    })
})
