const DelayValut = artifacts.require("DelayValut")

module.exports = function (deployer) {
  deployer.deploy(DelayValut)
}
