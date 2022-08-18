const DelayVault = artifacts.require("DelayVault")

const truffleAssert = require("truffle-assertions")
const { assert } = require("chai")

contract("Delay vault admin settings", (accounts) => {
    let instance
    const whiteListAddr = accounts[7]
    const lockedDealAddr = accounts[8]
    const minDelay = 1000
    const maxDelay = 2000
    const id = 1

    before(async () => {
        instance = await DelayVault.new()
    })

    it("should set WhiteList", async () => {
        await instance.setWhiteListAddress(whiteListAddr)
        await instance.setWhiteListId(id)
        const whiteList = await instance.WhiteListAddress()
        const whiteListId = await instance.WhiteListId()
        assert.equal(whiteList.toString(), whiteListAddr)
        assert.equal(whiteListId, id)
    })

    it("should set LockedDeal", async () => {
        await instance.setLockedDealAddress(lockedDealAddr)
        const lockedDeal = await instance.LockedDealAddress()
        assert.equal(lockedDealAddr, lockedDeal.toString())
    })

    it("should set min/max delay", async () => {
        await instance.setMaxDelay(maxDelay)
        await instance.setMinDelay(minDelay)
        const max = await instance.MaxDelay()
        const min = await instance.MinDelay()
        assert.equal(max.toString(), maxDelay.toString())
        assert.equal(min.toString(), minDelay.toString())
    })

    it("should revert with the same value", async () => {
        await truffleAssert.reverts(instance.setMaxDelay(maxDelay), "can't set the same value")
        await truffleAssert.reverts(instance.setMinDelay(minDelay), "can't set the same value")
        await truffleAssert.reverts(instance.setWhiteListId(id), "can't set the same value")
        await truffleAssert.reverts(instance.setLockedDealAddress(lockedDealAddr), "can't set the same address")
        await truffleAssert.reverts(instance.setWhiteListAddress(whiteListAddr), "can't set the same address")
    })

    it("should revert with delay setup", async () => {
        await truffleAssert.reverts(
            instance.setMaxDelay(minDelay - 1),
            "the maximum delay can't be less than the minimum delay!"
        )
        await truffleAssert.reverts(
            instance.setMinDelay(maxDelay + 1),
            "the minimum delay can't be greater than the maximum delay!"
        )
    })
})
