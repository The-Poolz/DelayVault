const DelayVault = artifacts.require("DelayVault");
const multisigWalletAddress = "0x1234567890123456789012345678901234567890"; // replace with the actual multisig wallet address
//full information about contract controls, can be found in https://office.poolz.finance/ 
module.exports = async function (deployer, network, accounts) {
  // Deploy the DelayVault contract and set the initial governor to the deployer
  await deployer.deploy(DelayVault);
  const delayVaultInstance = await DelayVault.deployed();
  const deployerAddress = accounts[0];
  await delayVaultInstance.setGovernerContract(deployerAddress);

  // Transfer ownership to the multisig wallet (only for non-testnet and non-local networks)
  if (network !== "test" && network !== "development") {
    if (multisigWalletAddress == "0x1234567890123456789012345678901234567890") throw "replace with the actual multisig wallet address!"
    await delayVaultInstance.transferOwnership(multisigWalletAddress);
  }
};
