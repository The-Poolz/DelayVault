const MultiSender = artifacts.require("DelayValut")
const TestToken = artifacts.require("ERC20Token")

contract("DelayValut", (accounts) => {
    let instance, Token

    before(async () => {
        instance = await MultiSender.new()
        Token = await TestToken.new('TestToken', 'TEST')
    })
    
    it('test', async () => {

    })
})
