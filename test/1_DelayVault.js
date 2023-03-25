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
            "start delay less than minimum start delay"
        )
    })

    it("should revert invalid finish delay", async () => {
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, week, week, day),
            "finish delay less than minimum finish delay"
        )
    })

    it("should revert invalid cliff delay", async () => {
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        await token.approve(instance.address, amount)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, week, day, week),
            "cliff delay less than minimum cliff delay"
        )
    })

    it("should revert invalid timestamp", async () => {
        await instance.setMinDelays(token.address, amounts, startDelays, cliffDelays, finishDelays)
        await token.approve(instance.address, amount)
        const maxDelayLimit = 604800 // 1 week in seconds
        const oldDelay = await instance.MaxDelay()
        await instance.setMaxDelay(maxDelayLimit)
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, week * 2, day, day),
            "Delay greater than Allowed"
        )
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, day, week * 2, day),
            "Delay greater than Allowed"
        )
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, day, day, week * 2),
            "Delay greater than Allowed"
        )
        await truffleAssert.passes(instance.CreateVault(token.address, amount, week, week, week))
        await instance.Withdraw(token.address)
        // bring back the old delay
        await instance.setMaxDelay(oldDelay)
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
            "start delay less than previous start delay"
        )
        await truffleAssert.reverts(
            instance.CreateVault(token.address, amount, week, week, twoDays),
            "finish delay less than previous finish delay"
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
            "Invalid parameters: increase at least one value"
        )
    })

    it("withdraw tokens when no locked deal", async () => {
        const owner = accounts[2]
        const token = await TestToken.new("TestToken", "TEST")
        await instance.setLockedDealAddress(constants.ZERO_ADDRESS)
        await token.transfer(owner, amount)
        await token.approve(instance.address, amount, { from: owner })
        await instance.setTokenStatusFilter(token.address, true)
        await instance.CreateVault(token.address, amount, week, week, week, { from: owner })
        const oldOwnerBalance = await token.balanceOf(owner)
        assert.equal(oldOwnerBalance.toString(), 0)
        await instance.Withdraw(token.address, { from: owner })
        const ownerBalance = await token.balanceOf(owner)
        assert.notEqual(ownerBalance, oldOwnerBalance)
        assert.equal(ownerBalance.toString(), amount.toString())
    })

    it("swap approve status", async () => {
        const token = await TestToken.new("TestToken", "TEST", { from: accounts[1] })
        await token.approve(instance.address, amount, { from: accounts[1] })
        await instance.setTokenStatusFilter(token.address, true)
        await instance.CreateVault(token.address, amount, week, week, week * 2, { from: accounts[1] })
        const defaultStatus = await instance.Allowance(token.address, accounts[1])
        assert.equal(defaultStatus, false)
        await instance.approveTokenRedemption(token.address, true, { from: accounts[1] })
        const vaultStatus = await instance.Allowance(token.address, accounts[1])
        assert.equal(vaultStatus, true)
    })

    it("increase only timestamps", async () => {
        // Create new vault
        const token = await TestToken.new("TestToken", "TEST")
        await token.approve(instance.address, amount)
        await instance.setTokenStatusFilter(token.address, true)
        const startDelay = week
        const cliffDelay = week
        const finishDelay = week * 2
        await instance.CreateVault(token.address, amount, startDelay, cliffDelay, finishDelay)
        // can't set the same params
        await truffleAssert.reverts(
            instance.CreateVault(token.address, 0, startDelay, cliffDelay, finishDelay),
            "Invalid parameters: increase at least one value"
        )
        const newStartDelay = startDelay * 2
        const newCliffDelay = cliffDelay * 2
        const newFinishDelay = finishDelay * 2
        // increase only startDelay
        await truffleAssert.passes(instance.CreateVault(token.address, 0, newStartDelay, cliffDelay, finishDelay))
        // increase only cliffDelay
        await truffleAssert.passes(instance.CreateVault(token.address, 0, newStartDelay, newCliffDelay, finishDelay))
        // increase only finishDelay
        await truffleAssert.passes(instance.CreateVault(token.address, 0, newStartDelay, newCliffDelay, newFinishDelay))
        const vaultMap = await instance.VaultMap(token.address, accounts[0])
        assert.equal(vaultMap.StartDelay.toString(), newStartDelay.toString())
        assert.equal(vaultMap.CliffDelay.toString(), newCliffDelay.toString())
        assert.equal(vaultMap.FinishDelay.toString(), newFinishDelay.toString())
    })
})
