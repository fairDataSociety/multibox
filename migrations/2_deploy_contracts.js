const Multibox = artifacts.require("Multibox");
const KeyValueTree = artifacts.require("KeyValueTree");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
};
