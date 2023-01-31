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
    const week = day * 7
    const twoWeeks = day * 14
    const cliffTimes = [day, twoDays, week]
    const lockPeriods = [day, twoDays, week]
    const amounts = [250, 1000, 20000]

    before(async () => {
        instance = await DelayVault.new()
        const tokensAmount = 3
        for (let i = 0; i < tokensAmount; i++) {
            tokens[i] = await TestToken.new("TestToken" + i, "TEST" + i)
            addresses.push(tokens[i].address)
        }
    })

    it("should get delay limit", async () => {
        const amounts = [10, 20, 30]
        await instance.setMinDelays(tokens[0].address, amounts, lockPeriods, cliffTimes)
        const result = await instance.GetDelayLimits(tokens[0].address)
        assert.equal(result[0].toString(), amounts.toString())
        assert.equal(result[1].toString(), lockPeriods.toString())
    })

    it("get min delay", async () => {
        // amounts            start times
        // ___________________________________________________
        // 0 - 249          |0 - day-1        | no limit      |
        // 250 - 999        |day - twoDays-1  | first limit   |
        // 1000 - 19999     |twoDays - week-1 | second limit  |
        // 20000 - infinity |week - inifinity | third limit   |
        //````````````````````````````````````````````````````
        const lockPeriods = [day, week, twoWeeks]
        await instance.setMinDelays(tokens[0].address, amounts, lockPeriods, cliffTimes)
        const dayDelay = await instance.GetMinDelay(tokens[0].address, amounts[0])
        assert.equal(dayDelay.toString(), day.toString())
        const zeroDelay = await instance.GetMinDelay(tokens[0].address, amounts[0] - 1)
        assert.equal(zeroDelay.toString(), 0)
        const weekDelay = await instance.GetMinDelay(tokens[0].address, amounts[1])
        assert.equal(weekDelay.toString(), week.toString())
        const maxDelay = await instance.GetMinDelay(tokens[0].address, amounts[2])
        assert.equal(maxDelay.toString(), twoWeeks.toString())
    })

    it("get cliff time", async () => {
        // amounts            finish times
        // ___________________________________________________
        // 0 - 249          |0 - day-1        | no limit      |
        // 250 - 999        |day - twoDays-1  | first limit   |
        // 1000 - 19999     |twoDays - week-1 | second limit  |
        // 20000 - infinity |week - inifinity | third limit   |
        //````````````````````````````````````````````````````
        await instance.setMinDelays(tokens[0].address, amounts, lockPeriods, cliffTimes)
        const dayCliffTime = await instance.GetCliffTime(tokens[0].address, amounts[0])
        assert.equal(dayCliffTime.toString(), day.toString())
        const twoDaysCliffTime = await instance.GetCliffTime(tokens[0].address, amounts[1])
        assert.equal(twoDaysCliffTime.toString(), twoDays.toString())
        const maxCliffTime = await instance.GetCliffTime(tokens[0].address, amounts[2])
        assert.equal(maxCliffTime.toString(), week.toString())
        const noAmountlimit = 249
        const zeroCliffTime = await instance.GetCliffTime(tokens[0].address, amounts[0] - 1)
        assert.equal(zeroCliffTime.toString(), 0)
    })

    it("should revert when not ordered amount", async () => {
        const amounts = [1000, 500, 10000]
        const lockPeriods = [day, week, twoWeeks]
        await truffleAssert.reverts(
            instance.setMinDelays(tokens[0].address, amounts, lockPeriods, cliffTimes),
            "amounts should be ordered"
        )
    })

    it("should revert when not ordered delays", async () => {
        const lockPeriods = [day, week, twoDays]
        await truffleAssert.reverts(
            instance.setMinDelays(tokens[0].address, amounts, lockPeriods, cliffTimes),
            "delays should be sorted"
        )
    })

    it("should get my token addresses", async () => {
        const amounts = [amount, amount * 2, amount * 3]
        const lockPeriods = [week, week * 2, week * 3]
        for (let i = 0; i < tokens.length; i++) {
            await instance.setMinDelays(tokens[i].address, amounts, lockPeriods, cliffTimes)
            await tokens[i].approve(instance.address, amount)
            await instance.CreateVault(tokens[i].address, amount, week)
        }
        const allMyTokens = await instance.GetAllMyTokens(accounts[0])
        const myTokens = await instance.GetMyTokens(accounts[0])
        assert.equal(allMyTokens.toString(), addresses.toString())
        assert.equal(myTokens.toString(), addresses.toString())
    })

    it("should return all data", async () => {
        //create token
        token = await TestToken.new("Poolz", "$POOLZ")
        await instance.setMinDelays(token.address, amounts, lockPeriods, cliffTimes)
        //create vaults
        for (let i = 0; i < accounts.length; i++) {
            await token.transfer(accounts[i], amount)
            await token.approve(instance.address, amount, { from: accounts[i] })
            await instance.CreateVault(token.address, amount, week, { from: accounts[i] })
        }
        const data = await instance.GetAllUsersData(token.address)
        assert.equal(data[0].length, data[1].length)
        assert.equal(data[0].length, accounts.length)
        for (let i = 0; i < accounts.length; i++) {
            assert.equal(data[0][i], accounts[i])
            assert.equal(data[1][i][0], amount)
        }
    })
})
