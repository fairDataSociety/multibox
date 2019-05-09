const Multibox = artifacts.require("Multibox");
const KeyValueTree = artifacts.require("KeyValueTree");


contract('MultiBox', (accounts) => {
  it('should initialise and create root folder', async () => {
    const multiBoxInstance = await Multibox.deployed();

    const multiBoxInstance2 = await Multibox.at(multiBoxInstance.address);

    const keyValueTreeContractAddress = await multiBoxInstance.init({ from: accounts[0] });

    const roots = await multiBoxInstance.getRoots({ from: accounts[0] });

    assert.equal(roots.length, 1, "root was not created...");   
  });
});