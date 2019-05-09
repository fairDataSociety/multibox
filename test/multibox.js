const Multibox = artifacts.require("Multibox");
const KeyValueTree = artifacts.require("KeyValueTree");


contract('Multibox', (accounts) => {
    it('should initialise and create root folder', async () => {
        const multiBoxInstance = await Multibox.deployed();
        //const multiBoxInstance2 = await Multibox.at(multiBoxInstance.address);

        const keyValueTreeContractAddress = await multiBoxInstance.init({ from: accounts[0] });

        const roots = await multiBoxInstance.getRoots({ from: accounts[0] });
        assert.equal(roots.length, 1, "root was not created...");
    });
    it('creating multiple roots', async () => {
        const multiBoxInstance = await Multibox.deployed();
        let atIndex = 0;
        //const keyValueTreeContractAddress = await multiBoxInstance.init({ from: accounts[0] });

        const createRoot = await multiBoxInstance.createRoot(accounts[0], { from: accounts[0] });

        let roots = await multiBoxInstance.getRoots({ from: accounts[0] });
        assert.equal(roots.length, 2, "2 roots were not created...");

        let createRoot2 = await multiBoxInstance.createRoot(accounts[0], { from: accounts[0] });
        roots = await multiBoxInstance.getRoots({ from: accounts[0] });
        assert.equal(roots.length, 3, "3 roots were not created...");

        let newLen = await multiBoxInstance.removeRoot(atIndex, { from: accounts[0] });
        roots = await multiBoxInstance.getRoots({ from: accounts[0] });
        assert.equal(roots.length, 3, "removed root 0 - should not be possible");

        newLen = await multiBoxInstance.removeRoot(atIndex + 1 , { from: accounts[0] });
        roots = await multiBoxInstance.getRoots({ from: accounts[0] });
        assert.equal(roots.length, 2, "1st root removed");

        newLen = await multiBoxInstance.removeRoot(atIndex , { from: accounts[1] });
        roots = await multiBoxInstance.getRoots({ from: accounts[0] });
        assert.equal(roots.length, 2, "2 non owner CAN remove root");
    });

    /*
    it('create 2 mb, init both, share kvt2 with kvt2', async () => {
        const mb1 = await Multibox.deployed();
        const mb2 = await Multibox.deployed();

        const kvt1 = await mb1.init({ from: accounts[0] });
        const kvt2 = await mb2.init({ from: accounts[1] });

        console.log(kvt1, kvt2);

        const roots = await mb1.getRoots({ from: accounts[0] });
        const roots1 = await mb2.getRoots({ from: accounts[1] });

        assert.equal(roots.length, 1, "root 1 was not created...");
        assert.equal(roots1.length, 2, "root 2 was not created...");
    });*/
});