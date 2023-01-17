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
        // amounts limits
        // _________________________________
        // 0 - 249          | no limit      |
        // 250 - 999        | first limit   |
        // 1000 - 19999     | second limit  |
        // 20000 - infinity | third limit   |
        //```````````````````````````````````
        const amounts = [250, 1000, 20000]
        const lockPeriods = [day, week, twoWeeks]
        await instance.setMinDelays(tokens[0].address, amounts, lockPeriods, cliffTimes)
        const dayDelay = await instance.GetMinDelay(tokens[0].address, 250)
        assert.equal(dayDelay.toString(), day.toString())
        const zeroDelay = await instance.GetMinDelay(tokens[0].address, 249)
        assert.equal(zeroDelay.toString(), 0)
        const weekDelay = await instance.GetMinDelay(tokens[0].address, 1100)
        assert.equal(weekDelay.toString(), week.toString())
        const maxDelay = await instance.GetMinDelay(tokens[0].address, 20000)
        assert.equal(maxDelay.toString(), twoWeeks.toString())
    })

    it("get cliff time", async () => {
        // min delays limits
        // _________________________________
        // 0 - day-1        | no limit      |
        // day - twoDays-1  | first limit   |
        // twoDays - week-1 | second limit  |
        // week - inifinity | third limit   |
        //```````````````````````````````````
        const amounts = [250, 1000, 20000]
        await instance.setMinDelays(tokens[0].address, amounts, lockPeriods, cliffTimes)
        const dayCliffTime = await instance.GetCliffTime(tokens[0].address, day)
        assert.equal(dayCliffTime.toString(), day.toString())
        const twoDaysCliffTime = await instance.GetCliffTime(tokens[0].address, twoDays + day)
        assert.equal(twoDaysCliffTime.toString(), twoDays.toString())
        const maxCliffTime = await instance.GetCliffTime(tokens[0].address, week * 2)
        assert.equal(maxCliffTime.toString(), week.toString())
        const halfDay = day / 2
        const zeroCliffTime = await instance.GetCliffTime(tokens[0].address, halfDay)
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
        const amounts = [250, 500, 10000]
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

    it("should get all data from vault", async () => {
        const amounts = [amount, amount * 2, amount * 3]
        const lockPeriods = [week, week * 2, week * 3]
        const token = await TestToken.new("TestToken", "TEST")
        await instance.setMinDelays(token.address, amounts, lockPeriods, cliffTimes)
        const users = [accounts[2], accounts[1]]
        await token.transfer(users[0], amount)
        await token.approve(instance.address, amount, { from: users[0] })
        await token.transfer(users[1], amount)
        await token.approve(instance.address, amount, { from: users[1] })
        await instance.CreateVault(token.address, amount, week, { from: users[0] })
        await instance.CreateVault(token.address, amount, week, { from: users[1] })
        const allData = await instance.GetAllUsersData(token.address)
        assert.equal(allData.length, users.length)
        assert.equal(allData[0].User, users[0], "check first user address")
        assert.equal(allData[1].User, users[1], "check second user address")
        assert.equal(allData[0].Amount, amount, "check first user amount")
        assert.equal(allData[1].Amount, amount, "check second user amount")
    })
})
