const MultiBox = artifacts.require("Multibox");
const KeyValueTree = artifacts.require("KeyValueTree");


contract('MultiBox', (accounts) => {
  it('should initialise and create root folder', async () => {
    const multiBoxInstance = await MultiBox.deployed();
    const keyValueTreeInstance = await KeyValueTree.deployed();

    console.log(1, multiBoxInstance.address, keyValueTreeInstance.address);

    const init = await multiBoxInstance.init.call({ from: accounts[0] });

    const roots = await multiBoxInstance.getRoots.call({ from: accounts[0] });

    debugger

    // should have deployed a new contract KeyValueTree
    assert.equal(roots.length, 1, "root was not created...");

    // const kvtContract = KeyValueTree.contractFromAddress(kvtcAddresses[0]);
    // const keyValueTreeContract = await multiBoxInstance.getRoot(roots[0]).call({ from: accounts[0] });
    // // assert.equal(roots.length, 1, "root was not created...");    
  });

  it('should create new folder', async () => {
    // const multiBoxInstance = await MultiBox.deployed();

    // const init = await multiBoxInstance.init.call({ from: accounts[0] });

    // const roots = await multiBoxInstance.getRoots.call({ from: accounts[0] });

    // assert.equal(balance.valueOf(), 10000, "10000 wasn't in the first account");
  });  
});