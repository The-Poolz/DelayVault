const DelayVault = artifacts.require("DelayVault")
const TestToken = artifacts.require("ERC20Token")

const constants = require("@openzeppelin/test-helpers/src/constants")
const { assert } = require("chai")
const truffleAssert = require("truffle-assertions")

contract("DelayVault", (accounts) => {
    let instance, token
    const amount = 1000
    const day = 86400
    const twoDays = day * 2
    const week = day * 7
    const amounts = [10, 30, 1000]
    const startDelays = [day, twoDays, week]
    const cliffDelays = [day, twoDays, week]
    const finishDelays = [day, twoDays, week]

    before(async () => {
        instance = await DelayVault.new()
        token = await TestToken.new("TestToken", "TEST")
    })

    it("should revert invalid start delay", async () => {
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, day, day, week),
            "delay less than min delay"
        )
    })

    it("should revert invalid finish delay", async () => {
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, week, week, day),
            "delay less than min delay"
        )
    })

    it("should revert invalid cliff delay", async () => {
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, week, day, week),
            "delay less than min delay"
        )
    })

    it("should create vault", async () => {
        await token.approve(instance.address, amount)
        let tx = await instance.CreateVault(token.address, amount, week, week, week * 2)
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
        await token.approve(instance.address, amount)
        // create second vault
        tx = await instance.CreateVault(token.address, amount, week, week, week * 2)
        const newAmount = tx.logs[tx.logs.length - 1].args.Amount
        // check full amount of the event
        assert.equal(newAmount.toString(), (amount * 2).toString())
    })

    it("should revert shorter blocking period than the last one", async () => {
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, day, twoDays, week * 2),
            "can't set a shorter start period than the last one"
        )
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, week, week, twoDays),
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
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, "0", "0", "0", "0"),
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
        await instance.CreateVault(token.address, amount, week, week, week, { from: owner })
        const oldOwnerBalance = await token.balanceOf(owner)
        assert.equal(oldOwnerBalance.toString(), 0)
        await instance.Withdraw(token.address, { from: owner })
        const ownerBalance = await token.balanceOf(owner)
        assert.notEqual(ownerBalance, oldOwnerBalance)
        assert.equal(ownerBalance.toString(), amount.toString())
    })

    it("buy back half tokens", async () => {
        const token = await TestToken.new("TestToken", "TEST", { from: accounts[1] })
        await token.approve(instance.address, amount, { from: accounts[1] })
        await instance.swapTokenStatusFilter(token.address)
        await instance.CreateVault(token.address, amount, week, week, week * 2, { from: accounts[1] })
        // buy back half tokens
        const tx = await instance.BuyBackTokens(token.address, amount / 2, { from: accounts[1] })
        // check events results
        assert.equal(tx.logs[tx.logs.length - 1].args.Token, token.address)
        assert.equal(tx.logs[tx.logs.length - 1].args.Amount, (amount / 2).toString())
        assert.equal(tx.logs[tx.logs.length - 1].args.RemaningAmount, (amount / 2).toString())
        // check vault data
        const data = await instance.VaultMap(token.address, accounts[1])
        assert.equal(data.Amount, (amount / 2).toString())
        assert.equal(data.StartDelay, week.toString())
        assert.equal(data.CliffDelay, week.toString())
        assert.equal(data.FinishDelay, (week * 2).toString())
    })

    it("buy back all tokens", async () => {
        const token = await TestToken.new("TestToken", "TEST", { from: accounts[1] })
        await token.approve(instance.address, amount, { from: accounts[1] })
        await instance.swapTokenStatusFilter(token.address)
        await instance.CreateVault(token.address, amount, week, week, week * 2, { from: accounts[1] })
        // buy back all tokens
        const tx = await instance.BuyBackTokens(token.address, amount, { from: accounts[1] })
        // check events results
        assert.equal(tx.logs[tx.logs.length - 1].args.Token, token.address)
        assert.equal(tx.logs[tx.logs.length - 1].args.Amount, amount.toString())
        assert.equal(tx.logs[tx.logs.length - 1].args.RemaningAmount, 0)
        // check vault data
        const data = await instance.VaultMap(token.address, accounts[1])
        assert.equal(data.Amount, 0)
        assert.equal(data.StartDelay, 0)
        assert.equal(data.CliffDelay, 0)
        assert.equal(data.FinishDelay, 0)
    })
})
