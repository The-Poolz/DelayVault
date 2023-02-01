const DelayVault = artifacts.require("DelayVault")
const TestToken = artifacts.require("ERC20Token")

const constants = require("@openzeppelin/test-helpers/src/constants")
const { assert, AssertionError } = require("chai")
const truffleAssert = require("truffle-assertions")

contract("DelayVault", (accounts) => {
    let instance, token
    const amount = 1000
    const day = 86400
    const twoDays = day * 2
    const week = day * 7
    const amounts = [10, 30, 1000]
    const startDelays = [day, twoDays, week]
    const finishDelays = [day, twoDays, week]

    before(async () => {
        instance = await DelayVault.new()
        token = await TestToken.new("TestToken", "TEST")
    })

    it("should revert invalid start delay", async () => {
        await instance.setMinDelays(token.address, amounts, startDelays, finishDelays)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, day, week),
            "start delay greater than min start delay"
        )
    })

    it("should revert invalid finish delay", async () => {
        await instance.setMinDelays(token.address, amounts, startDelays, finishDelays)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, week, day),
            "finish delay greater than min finish delay"
        )
    })

    it("should create vault", async () => {
        await token.approve(instance.address, amount)
        const tx = await instance.CreateVault(token.address, amount, week, week * 2)
        const tokenAddr = tx.logs[tx.logs.length - 1].args.Token
        const quantity = tx.logs[tx.logs.length - 1].args.Amount
        const startDelay = tx.logs[tx.logs.length - 1].args.StartDelay
        const finishDelay = tx.logs[tx.logs.length - 1].args.FinishDelay
        const owner = tx.logs[tx.logs.length - 1].args.Owner
        assert.equal(tokenAddr.toString(), token.address)
        assert.equal(quantity.toString(), amount.toString())
        assert.equal(startDelay.toString(), week.toString())
        assert.equal(finishDelay.toString(), (week * 2).toString())
        assert.equal(owner.toString(), accounts[0].toString())
    })

    it("should revert shorter blocking period than the last one", async () => {
        await instance.setMinDelays(token.address, amounts, startDelays, finishDelays)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, day, week * 2),
            "can't set a shorter start period than the last one"
        )
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, week, twoDays),
            "can't set a shorter finish period than the last one"
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
        await instance.setMinDelays(token.address, amounts, startDelays, finishDelays)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, "0", "0", "0"),
            "amount should be greater than zero"
        )
    })

    it("withdraw tokens when no locked deal", async () => {
        const owner = accounts[2]
        const token = await TestToken.new("TestToken", "TEST")
        await instance.setLockedDealAddress(constants.ZERO_ADDRESS)
        await token.transfer(owner, amount)
        await token.approve(instance.address, amount, { from: owner })
        await instance.swapTokenStatusFilter(token.address)
        await instance.CreateVault(token.address, amount, week, week, { from: owner })
        const oldOwnerBalance = await token.balanceOf(owner)
        assert.equal(oldOwnerBalance.toString(), 0)
        await instance.Withdraw(token.address, { from: owner })
        const ownerBalance = await token.balanceOf(owner)
        assert.notEqual(ownerBalance, oldOwnerBalance)
        assert.equal(ownerBalance.toString(), amount.toString())
    })
})
