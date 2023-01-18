const DelayVault = artifacts.require("DelayVault")
const TestToken = artifacts.require("ERC20Token")

const { assert } = require("chai")
const truffleAssert = require("truffle-assertions")

contract("DelayVault", (accounts) => {
    let instance, token
    const amount = 1000
    const day = 1 * 24 * 60 * 60
    const twoDays = day * 2
    const week = day * 7
    const amounts = [10, 30, 1000]
    const lockPeriods = [day, twoDays, week]
    const cliffTimes = [day, twoDays, week]

    before(async () => {
        instance = await DelayVault.new()
        token = await TestToken.new("TestToken", "TEST")
    })

    it("should revert invalid blocking period", async () => {
        await instance.setMinDelays(token.address, amounts, lockPeriods, cliffTimes)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, day),
            "minimum delay greater than lock time"
        )
    })

    it("should create vault", async () => {
        await token.approve(instance.address, amount)
        const tx = await instance.CreateVault(token.address, amount, week)
        const tokenAddr = tx.logs[tx.logs.length - 1].args.Token
        const quantity = tx.logs[tx.logs.length - 1].args.Amount
        const lockTime = tx.logs[tx.logs.length - 1].args.LockTime
        const owner = tx.logs[tx.logs.length - 1].args.Owner
        assert.equal(tokenAddr.toString(), token.address)
        assert.equal(quantity.toString(), amount.toString())
        assert.equal(lockTime.toString(), week.toString())
        assert.equal(owner.toString(), accounts[0].toString())
    })

    it("should revert shorter blocking period than the last one", async () => {
        await instance.setMinDelays(token.address, amounts, lockPeriods, cliffTimes)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, day),
            "can't set a shorter blocking period than the last one"
        )
    })

    it("should revert when empty vault", async () => {
        const token = await TestToken.new("TestToken", "TEST")
        await instance.setLockedDealAddress(accounts[1])
        await truffleAssert.reverts(instance.Withdraw(token.address), "vault is already empty")
    })

    it("should revert zero amount", async () => {
        token = await TestToken.new("TestToken", "TEST")
        await token.approve(instance.address, amount)
        await instance.setMinDelays(token.address, amounts, lockPeriods, cliffTimes)
        await truffleAssert.reverts(instance.CreateVault(token.address, "0", "0"), "amount should be greater than zero")
    })
})