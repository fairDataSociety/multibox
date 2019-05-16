//const Web3 = require('web3');
//const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:9545'));


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
        assert.equal(accounts[0], owner, "multibox 1 is not owned by account 0");
    });

    it('share roots same account two multiboxes', async () => {
        const mb1 = await Multibox.deployed();
        var mb2 = await Multibox.new();

        const kvtTx = await mb2.init({ from: accounts[0] });

        let rootsTx = await mb2.createRoot(accounts[0], { from: accounts[0] });
        let roots = await mb2.getRoots({ from: accounts[0] });
        //console.log(roots); // should contain 2 roots

        assert.equal(roots.length, 2, "mb2 did not create new root...");

        let shared = mb1.addRoot(roots[0], { from: accounts[0] }); 
        roots = await mb1.getRoots({ from: accounts[0] });
        assert.equal(roots.length, 2, "root was not shared with multibox1...");
    });
    it('multibox can not be initialized from different account', async () => {
        const mb1 = await Multibox.deployed();
        var mb2 = await Multibox.new({ from: accounts[1] });

        let owner = await mb2.owner();
        assert.equal(accounts[1], owner, "multibox 2 is not owned by account 1");

        let kvtTx = await mb2.init({ from: accounts[0] });
        let roots = await mb2.getRoots({ from: accounts[1] });
        assert.equal(roots.length, 0, "mb2 was initialized from wrong account");
    });
    it('share roots different account', async () => {
        const mb1 = await Multibox.deployed();
        var mb2 = await Multibox.new({ from: accounts[1] });

        let kvtTx = await mb2.init({ from: accounts[1] });
        let rootsTx = await mb2.createRoot(accounts[0], { from: accounts[1] });
        let roots = await mb2.getRoots({ from: accounts[1] });

        
        assert.equal(roots.length, 2, "mb2 did not create new root...");

        let newRootTx = mb1.addRoot(roots[1], { from: accounts[1] });
        roots = await mb1.getRoots({ from: accounts[0] });

        //console.log(roots);
        assert.equal(roots.length, 3, "root was not shared with multibox 1...");
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

        let roots = await mb1.getRoots({ from: accounts[0] });
        //console.log(roots);

        let rootsTx = await mb1.createRoot(accounts[1], { from: accounts[0] });
        roots = await mb1.getRoots({ from: accounts[0] });

        //console.log(roots);
        assert.equal(roots.length, 4, "additional root for other user access was not created...");
    });

    it('get shared node', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt  = await KeyValueTree.at(roots[0]);
        let sharedNodeId = await kvt.getSharedId({ from: accounts[0] });

        assert.notEqual(sharedNodeId, 0, "didn't got sharedNode");
    });

    it('get kvt nodes', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);

        let nodes = await kvt.getNodes({ from: accounts[0] });
        assert.notEqual(nodes.length, 0, "got nodes");

        //console.log('       num folders:' + folders.length);
        //console.log('       folder:' + folders[0]);
    });
    it('shared node is node 0', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let sharedNodeId = await kvt.getSharedId({ from: accounts[0] });
        let nodes = await kvt.getNodes({ from: accounts[0] });

        //console.log('        nodes:' + nodes);
        //console.log('       nodeId:' + nodes[0]);
        //console.log(' sharedNodeId:' + sharedNodeId);

        assert.equal(sharedNodeId, nodes[0], "sharedNode is not node[0]");
        
        //let keys = await kvt.getKeys(nodes[0], { from: accounts[0] });
        //console.log('       keys:'  + keys.length);
    });
    it('setKeyValue to node', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let sharedNodeId = await kvt.getSharedId({ from: accounts[0] });

        let keyToWrite = "0x000000000000000000000000000000000000000000000000000000000000b07b";
        let valueToWrite = "0x1111111111111111111111111111111111111111111111111111111111111111";

        let keys = await kvt.getKeys(sharedNodeId, { from: accounts[0] });
        let wasWritenTx = await kvt.setKeyValue(sharedNodeId, keyToWrite, valueToWrite, { from: accounts[0] });

        let wasWriten = await kvt.getValue(sharedNodeId, keyToWrite, { from: accounts[0] });
        assert.equal(wasWriten, valueToWrite, "value was not written");

        let allValuesWritten = await kvt.getNodeValuesForAKey(sharedNodeId, keyToWrite, { from: accounts[0] });

        let valueCheck = await kvt.getValue(sharedNodeId, keyToWrite, { from: accounts[0] });
        assert.equal(valueCheck, valueToWrite, "not correct written");

        //console.log(allValuesWritten);
        //console.log('       written:' + valueCheck);
    });
    it('writeKeyValue to node', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let sharedNodeId = await kvt.getSharedId({ from: accounts[0] });
        let keyToWrite   = "0x0000000000000000000000000000000000000000000000000000000000002222";
        let valueToWrite = "0x2222222222222222222222222222222222222222222222222222222222222222";

        let wasWritenTx = await kvt.writeKeyValue(sharedNodeId, keyToWrite, valueToWrite, { from: accounts[0] });

        let wasWriten = await kvt.getValue(sharedNodeId, keyToWrite, { from: accounts[0] });
        assert.equal(wasWriten, valueToWrite, "value was not written");
        
        let allValuesWritten = await kvt.getNodeValuesForAKey(sharedNodeId, keyToWrite, { from: accounts[0] });
        //console.log(allValuesWritten);
        
        let numValues = await kvt.getValuesCount(sharedNodeId, { from: accounts[0] });
        let numKeys = await kvt.getKeysCount(sharedNodeId, { from: accounts[0] });
        //console.log('       written:' + valueWritten);
        //console.log('       values count:' + numValues);
        //console.log('       keys count:' + numKeys);
        assert.equal(numValues.toString(), numKeys.toString(), "miscount key/value");
    });
    it('write to root node from other account', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let nodeId = await kvt.getRootId({ from: accounts[0] });
        let keyToWrite = "0x0000000000000000000000000000000000000000000000000000000000003333";
        let valueToWrite = "0x3333333333333333333333333333333333333333333333333333333333333333";

        let wasWritenTx = await kvt.setKeyValue(nodeId, keyToWrite, valueToWrite, { from: accounts[1] });
        let count = await kvt.getValuesCount(nodeId, keyToWrite, { from: accounts[0] });
        //console.log(count);
        assert.equal(count.toString(), "1", "value was written even when user had no access");
    });
    it('write to shared node from other account', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let nodeId = await kvt.getSharedId({ from: accounts[0] });
        let keyToWrite = "0x0000000000000000000000000000000000000000000000000000000000003333";
        let valueToWrite = "0x3333333333333333333333333333333333333333333333333333333333333333";

        let wasWritenTx = await kvt.setKeyValue(nodeId, keyToWrite, valueToWrite, { from: accounts[1] });
        let count = await kvt.getValuesCount(nodeId, keyToWrite, { from: accounts[0] });

        //console.log(count);
        assert.equal(count.toString(), "3", "third value was not written to shared node");
    });
    it('get root children', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let nodeId = await kvt.getRootId({ from: accounts[0] });
        let children = await kvt.getChildren(nodeId, { from: accounts[0] });

        //console.log(children);
        //console.log(children.length);
        assert.equal(children.length, 1, "root should have one child");
    });
    it('get shared children, add child to shared, add child to first child', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let nodeId = await kvt.getSharedId({ from: accounts[0] });
        let children = await kvt.getChildren(nodeId, { from: accounts[0] });
        assert.equal(children.length, 0, "shared should have no child");

        let newNodeId = "0x1231231231231231231231231231231231231231231231231231231231239999";
        let nodeIdTx = await kvt.addChildNode(nodeId, newNodeId, { from: accounts[0] });

        children = await kvt.getChildren(nodeId, { from: accounts[0] });
        assert.equal(children.length, 1, "shared should have 1 child");
        //console.log(children);

        let new2NodeId = "0x1231231231231231231231231231231231231231231238888888888888888888";
        let nodeId2Tx = await kvt.addChildNode(children[0], new2NodeId, { from: accounts[0] });

        children = await kvt.getChildren(children[0], { from: accounts[0] });
        assert.equal(children.length, 1, "first child should have have 1 child");
        //console.log(children);
    });
    it('get KeysValues', async () => {
        const mb1 = await Multibox.deployed();
        let roots = await mb1.getRoots({ from: accounts[0] });
        let kvt = await KeyValueTree.at(roots[0]);
        let nodeId = await kvt.getSharedId({ from: accounts[0] });

        let count = await kvt.getKeysCount(nodeId, { from: accounts[0] });

        assert.equal(count.toString(), "3", "keysValue pairs not received");

        let keysValues = await kvt.getKeysValues(nodeId, { from: accounts[0] });
        let kv = await kvt.getKeyValueAt(nodeId, 0, { from: accounts[0] });

        //console.log(keysValues);
        //console.log(kv);
        //console.log(keysValues.length);
    });
    it('ecrecover result matches address', async function () {
        var mb1 = await Multibox.deployed();
        var msg = '0x8CbaC5e4d803bE2A3A5cd3DbE7174504c6DD0c1C';

        var h = web3.sha3(msg);
        var sig = web3.eth.sign(address, h).slice(2);
        var r = `0x${sig.slice(0, 64)}`;
        var s = `0x${sig.slice(64, 128)};`
        var v = web3.toDecimal(sig.slice(128, 130)) + 27;

        var result = await mb1.testRecovery.call(h, v, r, s);
        assert.equal(result, address);
    })

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