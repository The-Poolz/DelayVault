const DelayVault = artifacts.require("DelayVault")
const truffleAssert = require("truffle-assertions")
const TestToken = artifacts.require("ERC20Token")

const { assert } = require("chai")
const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants")

contract("Delay vault data", (accounts) => {
    let instance,
        tokens = []
    const amount = 1000
    let addresses = []
    const day = 1 * 24 * 60 * 60
    const twoDays = day * 2
    const week = day * 7
    const twoWeeks = day * 14
    const startDelays = [day, twoDays, week]
    const cliffDelays = [0, 0, 0]
    const finishDelays = [day, twoDays, week]
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
        await instance.setMinDelays(tokens[0].address, amounts, startDelays, cliffDelays, finishDelays)
        const result = await instance.GetDelayLimits(tokens[0].address)
        assert.equal(result[0].toString(), amounts.toString())
        assert.equal(result[1].toString(), startDelays.toString())
        assert.equal(result[2].toString(), cliffDelays.toString())
        assert.equal(result[3].toString(), finishDelays.toString())
    })

    it("get limit delays", async () => {
        // amounts            start delays         finish Delays
        // _______________________________________________________________________________
        // 0 - 249          |0 - day-1           | 0 - twoDays-1          | no limit      |
        // 250 - 999        |day - week-1        | twoDays - twoWeeks-1   | first limit   |
        // 1000 - 19999     |week - twoWeeks-1   | twoWeeks - month-1     | second limit  |
        // 20000 - infinity |twoWeeks - inifinity| month - inifinity      | third limit   |
        //`````````````````````````````````````````````````````````````````````````````````
        const startDelays = [day, week, twoWeeks]
        const month = twoWeeks * 4
        const finishDelays = [twoDays, twoWeeks, month]
        await instance.setMinDelays(tokens[0].address, amounts, startDelays, cliffDelays, finishDelays)
        let delays = await instance.GetMinDelays(tokens[0].address, 250)
        assert.equal(delays._startDelay.toString(), day.toString())
        assert.equal(delays._finishDelay.toString(), twoDays.toString())
        delays = await instance.GetMinDelays(tokens[0].address, 249)
        assert.equal(delays._startDelay.toString(), 0)
        assert.equal(delays._finishDelay.toString(), 0)
        delays = await instance.GetMinDelays(tokens[0].address, 1100)
        assert.equal(delays._startDelay.toString(), week.toString())
        assert.equal(delays._finishDelay.toString(), twoWeeks.toString())
        delays = await instance.GetMinDelays(tokens[0].address, 20000)
        assert.equal(delays._startDelay.toString(), twoWeeks.toString())
        assert.equal(delays._finishDelay.toString(), month.toString())
    })

    it("get token filter status", async () => {
        const token = await TestToken.new("TestToken", "TEST")
        // check unknown token
        let status = await instance.GetTokenFilterStatus(token.address)
        assert.equal(status, false)
        // check the state after calling the set minimum delay
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        status = await instance.GetTokenFilterStatus(token.address)
        assert.equal(status, true)
        await instance.setTokenStatusFilter(token.address, false)
        status = await instance.GetTokenFilterStatus(token.address)
        assert.equal(status, false)
    })

    it("should revert when not ordered amount", async () => {
        const amounts = [1000, 500, 10000]
        await truffleAssert.reverts(
            instance.setMinDelays(tokens[0].address, amounts, startDelays, cliffDelays, finishDelays),
            "array should be ordered"
        )
    })

    it("should revert invalid indices", async () => {
        await truffleAssert.reverts(
            instance.GetUsersDataByRange(tokens[0].address, 100, 0),
            "_from index can't be greater than _to"
        )
        await truffleAssert.reverts(
            instance.GetMyTokensByRange(tokens[0].address, 100, 0),
            "_from index can't be greater than _to"
        )
        await truffleAssert.reverts(instance.GetUsersDataByRange(tokens[0].address, 5, 10), "index out of range")
        await truffleAssert.reverts(instance.GetMyTokensByRange(tokens[0].address, 5, 10), "index out of range")
    })

    it("should get my token addresses", async () => {
        const amounts = [amount, amount * 2, amount * 3]
        const finishDelays = [week, week * 2, week * 3]
        for (let i = 0; i < tokens.length; i++) {
            await instance.setMinDelays(tokens[i].address, amounts, startDelays, cliffDelays, finishDelays)
            await tokens[i].approve(instance.address, amount)
            await instance.CreateVault(tokens[i].address, amount, week, week, week)
        }
        const from = 0
        const to = tokens.length - 1
        const allMyTokens = await instance.GetMyTokensByRange(accounts[0], from, to)
        const tokenLength = await instance.GetMyTokensLengthByUser(accounts[0])
        const myTokens = await instance.GetMyTokens(accounts[0])
        assert.equal(allMyTokens.toString(), addresses.toString())
        assert.equal(myTokens.toString(), addresses.toString())
        assert.equal(tokenLength, tokens.length)
    })

    it("check my token duplicate", async () => {
        const user = accounts[5]
        const token = await TestToken.new("TestToken", "TEST", { from: user })
        await token.approve(instance.address, amount)
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        await token.approve(instance.address, amount, { from: user })
        await instance.CreateVault(token.address, amount, week, week, week, { from: user })
        let myTokens = await instance.GetMyTokens(user)
        assert.equal(myTokens.toString(), token.address.toString())
        await token.approve(instance.address, amount, { from: user })
        // expand vault
        await instance.CreateVault(token.address, amount, week, week, week, { from: user })
        myTokens = await instance.GetMyTokens(user)
        // check dublication
        assert.equal(myTokens.toString(), token.address.toString())
    })

    it("should return all data", async () => {
        //create token
        token = await TestToken.new("Poolz", "$POOLZ")
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        // //create vaults
        for (let i = 0; i < accounts.length; i++) {
            await token.transfer(accounts[i], amount)
            await token.approve(instance.address, amount, { from: accounts[i] })
            await instance.CreateVault(token.address, amount, week, week, week, { from: accounts[i] })
        }
        const from = 0
        const to = accounts.length - 1
        const data = await instance.GetUsersDataByRange(token.address, from, to)
        const usersLength = await instance.GetUsersLengthByToken(token.address)
        assert.equal(data[0].length, data[1].length)
        assert.equal(data[0].length, accounts.length)
        for (let i = 0; i < accounts.length; i++) {
            assert.equal(data[0][i], accounts[i])
            assert.equal(data[1][i][0], amount)
        }
        assert.equal(usersLength.toString(), accounts.length.toString())
    })
    it("should return the correct checksum", async () => {
        const expectedChecksum = web3.utils.soliditySha3(accounts[0], ZERO_ADDRESS);
        const actualChecksum = await instance.getChecksum();
        assert.equal(actualChecksum, expectedChecksum);
      });      
})