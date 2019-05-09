
const Multibox = artifacts.require("Multibox");
const KeyValueTree = artifacts.require("KeyValueTree");


contract('Multibox', (accounts) => {
    it('should initialise and create root folder', async () => {
        const mb1 = await Multibox.deployed();
        const keyValueTreeContractAddress = await mb1.init({ from: accounts[0] });
        const roots = await mb1.getRoots({ from: accounts[0] });
        assert.equal(roots.length, 1, "root was not created...");
    });
    it('has an owner', async function () {
        const mb1 = await Multibox.deployed();
        let owner = await mb1.owner();
        assert.equal(accounts[0], owner);
    });

    it('share roots ', async () => {
        const mb1 = await Multibox.deployed();
        var mb2 = await Multibox.new();

        const kvt = await mb2.init({ from: accounts[0] });

        let roots = await mb2.createRoot(accounts[0], { from: accounts[0] });
        roots = await mb2.getRoots({ from: accounts[0] });

        assert.equal(roots.length, 2, "mb2 did not create new root...");

        let shared = mb1.addRoot(roots[1], { from: accounts[1] }); 
        roots = await mb1.getRoots({ from: accounts[0] });
        assert.equal(roots.length, 2, "root was not shared with multibox1...");
    });

    it('kvt has an owner', async function () {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt   = await KeyValueTree.at(roots[0]);

        let owner = await kvt .owner();
        assert.equal(accounts[0], owner);
    });

    it('many roots ', async () => {
        const mb1 = await Multibox.deployed();
        const kvt = await mb1.init({ from: accounts[0] });

        let roots = await mb1.createRoot(accounts[1], { from: accounts[0] });
        roots = await mb1.getRoots({ from: accounts[0] });

        assert.equal(roots.length, 3, "additional root for other user access was not created...");
    });

    it('get shared node', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt  = await KeyValueTree.at(roots[0]);
        let sharedNodeId = await kvt.getShared({ from: accounts[0] });

        assert.notEqual(sharedNodeId, 0, "didn't got sharedNode");
    });

    it('get kvt folders', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);

        let folders = await kvt.getAllFolders({ from: accounts[0] });
        assert.notEqual(folders.length, 0, "got folders");

        //console.log('       num folders:' + folders.length);
        //console.log('       folder:' + folders[0]);
    });
    it('get shared node', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let sharedNodeId = await kvt.getShared({ from: accounts[0] });
        let folders = await kvt.getAllFolders({ from: accounts[0] });

        let nodeId = await kvt.getNodeId(folders[0], { from: accounts[0] }); // lookup nodeId through folder
        assert.equal(sharedNodeId, nodeId, "shared folder does not map to sharedNodeId");
        
        let keys = await kvt.getKeys(nodeId, { from: accounts[0] });

        //console.log('       nodeId:' + sharedNodeId);
        //console.log('       keys:'  + keys.length);
        //console.log('       folder:' + folders[0]);
    });
    it('setKeyValue from folder', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let sharedNodeId = await kvt.getShared({ from: accounts[0] });
        let folders = await kvt.getAllFolders({ from: accounts[0] });

        let keyToWrite = "0x000000000000000000000000000000000000000000000000000000000000b07b";
        let valueToWrite = "0x1111111111111111111111111111111111111111111111111111111111111111";

        let keys = await kvt.getKeys(sharedNodeId, { from: accounts[0] });
        let wasWritenTx = await kvt.setKeyValueFolder(folders[0], keyToWrite, valueToWrite, { from: accounts[0] });

        let wasWriten = await kvt.getValue(sharedNodeId, keyToWrite, { from: accounts[0] });
        assert.equal(wasWriten, valueToWrite, "value was not written");

        let allValuesWritten = await kvt.getFolderValuesForAKey(sharedNodeId, folders[0], { from: accounts[0] });

        let valueCheck = await kvt.getValue(sharedNodeId, keyToWrite, { from: accounts[0] });
        assert.equal(valueCheck, valueToWrite, "not correct written");

        //console.log(allValuesWritten);
        //console.log('       written:' + valueCheck);
    });
    it('setKeyValue from nodeId', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let sharedNodeId = await kvt.getShared({ from: accounts[0] });
        let keyToWrite   = "0x0000000000000000000000000000000000000000000000000000000000002222";
        let valueToWrite = "0x2222222222222222222222222222222222222222222222222222222222222222";

        let folder = await kvt.getFolder(sharedNodeId, { from: accounts[0] });
        let wasWritenTx = await kvt.setKeyValue(sharedNodeId, keyToWrite, valueToWrite, { from: accounts[0] });

        let wasWriten = await kvt.getValue(sharedNodeId, keyToWrite, { from: accounts[0] });
        assert.equal(wasWriten, valueToWrite, "value was not written");
        
        let allValuesWritten = await kvt.getFolderValuesForAKey(folder, keyToWrite, { from: accounts[0] });
        //console.log(allValuesWritten);
        
        let numValues = await kvt.getValuesCount(sharedNodeId, { from: accounts[0] });
        let numKeys = await kvt.getKeysCount(sharedNodeId, { from: accounts[0] });


        //console.log('       written:' + valueWritten);
        //console.log('       values count:' + numValues);
        //console.log('       keys count:' + numKeys);

        assert.equal(numValues.toString(), numKeys.toString(), "miscount key/value");
    });
    //TODO
    // overwrite key
    // delete key
    // remove node 
    // remove child 
    // test access rights 
    

    /*
    it('many roots ', async () => {
        const multiBoxInstance = await Multibox.deployed();
        const kvt = await multiBoxInstance.init({ from: accounts[0] });

        let roots = await multiBoxInstance.createRoot(accounts[1], { from: accounts[0] });
        roots = await multiBoxInstance.getRoots({ from: accounts[0] });

        assert.equal(roots.length, 3, "additional root for other user access was not created...");
    }); */
    //const multiBoxInstance2 = await Multibox.at(multiBoxInstance.address);
});