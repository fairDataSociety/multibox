
const Multibox = artifacts.require("Multibox");
const KeyValueTree = artifacts.require("KeyValueTree");


contract('Multibox', (accounts) => {
    it('should initialise and create root folder', async () => {
        const mb1 = await Multibox.deployed();
        const keyValueTreeContractAddress = await mb1.init({ from: accounts[0] });
        const roots = await mb1.getRoots({ from: accounts[0] });
        assert.equal(roots.length, 1, "root was not created...");
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
        console.log('       num folders:' + folders.length);
        console.log('       folder:' + folders[0]);
        assert.notEqual(folders.length, 0, "got folders");
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

        console.log('       nodeId:' + sharedNodeId);
        console.log('       keys:'  + keys.length);
        console.log('       folder:' + folders[0]);
    });
    it('setKeyValue from folder', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let sharedNodeId = await kvt.getShared({ from: accounts[0] });
        let folders = await kvt.getAllFolders({ from: accounts[0] });

        let keys = await kvt.getKeys(sharedNodeId, { from: accounts[0] });
        let wasWriten = await kvt.setKeyValueFolder.call(folders[0], sharedNodeId, sharedNodeId, { from: accounts[0] });

        assert.equal(wasWriten, true, "value was not written");
        let allValuesWritten = await kvt.getFolderValuesForAKey.call(sharedNodeId, folders[0], { from: accounts[0] });

        console.log(allValuesWritten);
    });
    it('setKeyValue from nodeId', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let sharedNodeId = await kvt.getShared({ from: accounts[0] });

        let folder = await kvt.getFolder(sharedNodeId, { from: accounts[0] });
        let wasWriten = await kvt.setKeyValue.call(sharedNodeId, sharedNodeId, folder, { from: accounts[0] });
        assert.equal(wasWriten, true, "value was not written");
        
        let allValuesWritten = await kvt.getFolderValuesForAKey(folder, sharedNodeId, { from: accounts[0] });
        console.log(allValuesWritten);
        
        let valueWritten = await kvt.getValue(sharedNodeId, sharedNodeId, { from: accounts[0] });
        console.log('       written:' + valueWritten);
        let numValues = await kvt.getValuesCount(sharedNodeId, { from: accounts[0] });
        console.log('       values count:' + numValues);
        let numKeys = await kvt.getKeysCount(sharedNodeId, { from: accounts[0] });
        console.log('       keys count:' + numKeys);

    });

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