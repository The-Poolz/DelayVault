const DelayVault = artifacts.require("DelayVault")
const truffleAssert = require("truffle-assertions")
const TestToken = artifacts.require("ERC20Token")

const { assert } = require("chai")

contract("Delay vault data", (accounts) => {
    let instance,
        tokens = []
    const amount = 1000
    let addresses = []
    const day = 1 * 24 * 60 * 60
    const twoDays = day * 2
    const threeDays = day * 3
    const week = day * 7
    const twoWeeks = day * 14

    before(async () => {
        instance = await DelayVault.new()
        const tokensAmount = 3
        for (let i = 0; i < tokensAmount; i++) {
            tokens[i] = await TestToken.new("TestToken" + i, "TEST" + i)
            addresses.push(tokens[i].address)
        }
    })

    it("should get min delays", async () => {
        const amounts = [10, 20, 30]
        const lockPeriods = [day, twoDays, threeDays]
        await instance.setMinDelays(amounts, lockPeriods)
        const result = await instance.GetTokenLimits()
        assert.equal(result[0].toString(), amounts.toString())
        assert.equal(result[1].toString(), lockPeriods.toString())
    })

    it("get min delay", async () => {
        const amounts = [250, 500, 10000]
        const lockPeriods = [day, week, twoWeeks]
        await instance.setMinDelays(amounts, lockPeriods)
        const mediumDelay = await instance.GetMinDelay(750)
        assert.equal(mediumDelay.toString(), week.toString())
        const lowDelay = await instance.GetMinDelay(350)
        assert.equal(lowDelay.toString(), day.toString())
        const maxDelay = await instance.GetMinDelay(15000)
        assert.equal(maxDelay.toString(), twoWeeks.toString())
        const minDelay = await instance.GetMinDelay(100)
        assert.equal(minDelay.toString(), "0")
    })

    it("should revert when not ordered amount", async () => {
        const amounts = [1000, 500, 10000]
        const lockPeriods = [day, week, twoWeeks]
        await truffleAssert.reverts(instance.setMinDelays(amounts, lockPeriods), "amounts should be ordered")
    })

    it("should revert when not ordered delays", async () => {
        const amounts = [250, 500, 10000]
        const lockPeriods = [day, week, twoDays]
        await truffleAssert.reverts(instance.setMinDelays(amounts, lockPeriods), "delays should be sorted")
    })

    it("should get my token addresses", async () => {
        for (let i = 0; i < tokens.length; i++) {
            await tokens[i].approve(instance.address, amount)
            await instance.CreateVault(tokens[i].address, amount, week)
        }
        const allMyTokens = await instance.GetAllMyTokens()
        const myTokens = await instance.GetMyTokens()
        assert.equal(allMyTokens.toString(), addresses.toString())
        assert.equal(myTokens.toString(), addresses.toString())
    })
})
