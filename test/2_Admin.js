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
    const finishDelays = [day, week, week * 2]

    before(async () => {
        instance = await DelayVault.new()
        token = await TestToken.new("TestToken", "TEST")
    })

    it("should pause contract", async () => {
        await instance.Pause()
        await instance.setMinDelays(token.address, amounts, startDelays, finishDelays)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(instance.CreateVault(token.address, amount, 0, week), "Pausable: paused")
        await instance.Unpause()
        await instance.CreateVault(token.address, amount, 0, week)
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
        const tx = await instance.setMinDelays(token.address, amounts, startDelays, finishDelays)
        const resAmounts = tx.logs[0].args.Amounts
        const startDelArray = tx.logs[0].args.StartDelays
        const finishDelArray = tx.logs[0].args.FinishDelays
        const _token = tx.logs[0].args.Token
        assert.equal(amounts.toString(), resAmounts.toString())
        assert.equal(startDelays.toString(), startDelArray.toString())
        assert.equal(finishDelays.toString(), finishDelArray.toString())
        assert.equal(_token.toString(), token.address.toString())
    })

    it("should revert arrays with dirrent lengths", async () => {
        const invaliFinishTimes = [day, week]
        await truffleAssert.reverts(
            instance.setMinDelays(token.address, amounts, startDelays, invaliFinishTimes),
            "invalid array length"
        )
        const invalidStartDelays = [day, week]
        await truffleAssert.reverts(
            instance.setMinDelays(token.address, amounts, invalidStartDelays, finishDelays),
            "invalid array length"
        )
        const invalidAmounts = [10, 20, 30, 50]
        await truffleAssert.reverts(
            instance.setMinDelays(token.address, invalidAmounts, startDelays, finishDelays),
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
            instance.CreateVault(token.address, amount, 0, week),
            "there are no limits set for this token"
        )
    })

    it("should deactivate/activate token", async () => {
        await instance.setMinDelays(token.address, amounts, startDelays, finishDelays) // isActive = true
        await token.approve(instance.address, amount)
        await instance.swapTokenStatusFilter(token.address) // isActive = false
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, week, week),
            "there are no limits set for this token"
        )
        await instance.swapTokenStatusFilter(token.address) // isActive = true
        await truffleAssert.passes(instance.CreateVault(token.address, amount, week, week))
    })
})
