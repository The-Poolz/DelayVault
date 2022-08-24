const DelayVault = artifacts.require("DelayVault")
const TestToken = artifacts.require("ERC20Token")

const { assert } = require("chai")
const truffleAssert = require("truffle-assertions")

contract("DelayVault", (accounts) => {
    let instance, token
    const amount = 1000

    before(async () => {
        instance = await DelayVault.new()
        token = await TestToken.new("TestToken", "TEST")
    })

    it("should create vault", async () => {
        const week = 7 * 24 * 60 * 60
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

    // it("should revert invalid blocking period", async () => {
    //     const day = 1 * 24 * 60 * 60
    //     const twoDays = day * 2
    //     const threeDays = day * 3
    //     const amounts = [10, 30, 1000]
    //     const lockPeriods = [day, twoDays, threeDays]
    //     await instance.setMinDelays(amounts, lockPeriods)
    //     await token.approve(instance.address, amount)
    //     await truffleAssert.reverts(instance.CreateVault(token.address, amount, day), "Invalid blocking period!")
    //     await instance.CreateVault(token.address, amount - 1, twoDays)
    // })
})
