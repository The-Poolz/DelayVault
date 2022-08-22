const { assert } = require("chai")

const DelayVault = artifacts.require("DelayVault")
const TestToken = artifacts.require("ERC20Token")

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
})
