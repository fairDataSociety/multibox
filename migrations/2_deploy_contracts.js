const Multibox = artifacts.require("Multibox");
const KeyValueTree = artifacts.require("KeyValueTree");
const OOO = artifacts.require("OOO");

module.exports = async function(deployer, network, accounts) {
  await deployer.deploy(Multibox);
  await deployer.deploy(OOO);
  let mb = await Multibox.deployed();
};
