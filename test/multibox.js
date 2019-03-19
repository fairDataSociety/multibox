const MultiBox = artifacts.require("MultiBox");

contract('MultiBox', (accounts) => {
  it('should have version 1', async () => {
    const multiBoxInstance = await MultiBox.deployed();
    const version = await multiBoxInstance.getVersion.call();
    assert.equal(version, 1, "10000 wasn't in the first account");
  });

  // it('should create a new request for mailbox protocol', async () => {
  //   // ...
  // });

  // it('should retrieve requests that have been made to this contract', async () => {
  //   // ...
  // });  

  // ...
});