require('truffle-test-utils').init();

const ConsentManager = artifacts.require("ConsentManager");
const Consent = artifacts.require("Consent");

let swarmHash1 = '0xc016ed5d54e357cb4a7460cb1b13b3f499dc4f428453fec21613e9339faaeb3e';
let swarmHash2 = '0xc016ed5d54e357cb4a7460cb1b13b3f499dc4f428453fec21613e9339faaeb3f';

//just copy paste from ganache-cli now, later we can https://ethereum.stackexchange.com/questions/60995/how-to-get-private-keys-on-truffle-from-ganache-accounts
let privateKeyAcc0 = '0xb0b70b7e58eb33dedb35f228e97c5d8c36f5f91e431ffbd3041f48cb8c1fa986'
let privateKeyAcc1 = '0xc4d68f89dd70f1ee877dccd836b161e02dc3df7499777827c362027894e018e8'

const increaseTime = addSeconds => {
    web3.currentProvider.send({
        jsonrpc: "2.0", 
        method: "evm_increaseTime", 
        params: [addSeconds], id: 0
    })
}

contract('ConsentManager', (accounts) => {
  let cm
  beforeEach('setup contract for each test', async function () {
    cm = await ConsentManager.deployed();
  })  

  it('deploy master consent manager', async () => {
    assert.equal(cm.address.length, 42, "consent was not deployed...");
  });
    
  it('create and get consent', async () => {
    
    // createConsent(address payable dataUser, address payable dataSubject, bytes32 swarmLocation) public returns (Consent)    
    let tx = await cm.createConsent(accounts[0], accounts[1], swarmHash1, {from: accounts[0]});

    assert.equal(tx.receipt.status, true, "consent was not created...");
  });

  it('get user consents', async () => {
    // getUserConsents() public view returns (Consent[] memory)    
    let tx1 = await cm.getUserConsents();

    assert.equal(tx1.length, 1, "consent was not created...");
  });

  it('get subject consents', async () => {
    // getSubjectConsents() public view returns (Consent[] memory) 

    let tx1 = await cm.getSubjectConsents({from: accounts[1]});

    assert.equal(tx1.length, 1, "consent was not created...");
  });

  it('get consents for swarmHash', async () => {
    // getConsentsFor(bytes32 swarmHash) public view returns (Consent[] memory)

    let tx1 = await cm.getConsentsFor(swarmHash1);

    assert.equal(tx1.length, 1, "consent was not created...");    
  });

  it('update existing consents with new location', async () => {
    // updateConsent(Consent consent, bytes32 swarmLocation) public returns (Consent)

    let tx1 = await cm.getSubjectConsents({from: accounts[1]});

    let con = await Consent.at(tx1[0]);

    // console.log(con);

    let tx2 = await cm.updateConsent(tx1[0], swarmHash2, {from: accounts[1]});

    // let tx3 = await cm.getConsentsFor(swarmHash1);
    // let tx4 = await cm.getConsentsFor(swarmHash2);

    // assert.equal(tx3.length, 0, "consent was not updated...");
    // assert.equal(tx4.length, 1, "consent was not updated...");

    let tx5 = await con.swarmHash();
    assert.equal(tx5, swarmHash2, "consent was not updated...");

  });
   
  ///////////////////////////////////////////////////////////////////////////////
  // consent contract

  it('user signs consent', async () => {
    // signUser(bytes32 h, uint8 v, bytes32 r, bytes32 s)
    let tx1 = await cm.getUserConsents({from: accounts[0]});
    let con = await Consent.at(tx1[0]);

    let msg = tx1[0];
    let h = web3.utils.sha3(msg);

    let sigg = await web3.eth.sign(h, accounts[0], privateKeyAcc0);
    var sig = sigg.slice(2);
    var v = web3.utils.toDecimal(sig.slice(128, 130)) + 27;    
    var r = `0x${sig.slice(0, 64)}`;
    var s = `0x${sig.slice(64, 128)}`

    let tx2 = await con.signUser(h, v, r, s);

    let tx5 = await con.isUserSigned();

    assert.equal(tx5, true, "consent was not signed by user");
  });
  
  it('subject signs consent', async () => {
    // signSubject(bytes32 h, uint8 v, bytes32 r, bytes32 s)
    let tx1 = await cm.getSubjectConsents({from: accounts[1]});
    let con = await Consent.at(tx1[0]);

    let msg = tx1[0];
    let h = web3.utils.sha3(msg);

    let sigg = await web3.eth.sign(h, accounts[1], privateKeyAcc1);
    let sig = sigg.slice(2);
    let v = web3.utils.toDecimal(sig.slice(128, 130)) + 27;    
    let r = `0x${sig.slice(0, 64)}`;
    let s = `0x${sig.slice(64, 128)}`

    let tx2 = await con.signSubject(h, v, r, s);

    let tx5 = await con.isSubjectSigned();

    assert.equal(tx5, true, "consent was not signed by subject");    
  });

  it('subject signs consent', async () => {
    // signSubject(bytes32 h, uint8 v, bytes32 r, bytes32 s)
    let tx1 = await cm.getSubjectConsents({from: accounts[1]});
    let con = await Consent.at(tx1[0]);

    let tx5 = await con.isSigned();

    assert.equal(tx5, true, "consent was not signed");    
  });

  it('remove consent (only data subject)', async () => {
    // revokeConsent() 
    let tx1 = await cm.getSubjectConsents({from: accounts[1]});
    let con = await Consent.at(tx1[0]);
    let tx2 = await con.revokeConsent({from: accounts[1]});
    let tx3 = await con.isValid();

    assert.equal(tx3, false, "consent was not revoked...");    
  });  
});