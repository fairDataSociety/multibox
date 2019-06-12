const Multibox = artifacts.require("Multibox");
const KeyValueTree = artifacts.require("KeyValueTree");

module.exports = async function (deployer, network, accounts) {
    await deployer.deploy(Multibox, { gas: 6000000 });
    let mb = await Multibox.deployed();
};