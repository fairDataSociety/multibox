require('truffle-test-utils').init();

const ConsentManager = artifacts.require("ConsentManager");
const Consent = artifacts.require("Consent");

let swarmHash1 = '0xc016ed5d54e357cb4a7460cb1b13b3f499dc4f428453fec21613e9339faaeb3e';
let swarmHash2 = '0xc016ed5d54e357cb4a7460cb1b13b3f499dc4f428453fec21613e9339faaeb3f';

//just copy paste from ganache-cli now, later we can https://ethereum.stackexchange.com/questions/60995/how-to-get-private-keys-on-truffle-from-ganache-accounts
let privateKeyAcc0 = '0xeacfe7ae5571eadc79419eb7ebac89317734bd194bc40fdbe2177e78ab49d964'
let privateKeyAcc1 = '0xc34a7605f9bfa67763e580a8218fcdbac56aa93d4d93073714c215f37d2c5f0a'

let EthCrypto = require('eth-crypto');

const increaseTime = addSeconds => {
    web3.currentProvider.send({
        jsonrpc: "2.0", 
        method: "evm_increaseTime", 
        params: [addSeconds], id: 0
    })
}

contract('ConsentManager', (accounts) => {
  let cm
  let dataUser = accounts[0];
  let dataSubject = accounts[1];

  beforeEach('setup contract for each test', async function () {
    cm = await ConsentManager.deployed();
  })  

  it('deploy master consent manager', async () => {
    assert.equal(cm.address.length, 42, "consent was not deployed...");
  });
    
  it('create and get consent', async () => {
    
    // createConsent(address payable dataUser, address payable dataSubject, bytes32 swarmLocation) public returns (Consent)    
    let tx = await cm.createConsent(dataUser, dataSubject, swarmHash1, {from: dataUser});

    // console.log(tx)

    assert.equal(tx.receipt.status, true, "consent was not created...");
  });

  it('get user consents', async () => {
    // getUserConsents() public view returns (Consent[] memory)    
    let tx1 = await cm.getUserConsents();

    assert.equal(tx1.length, 1, "consent was not created...");
  });

  it('get subject consents', async () => {
    // getSubjectConsents() public view returns (Consent[] memory) 

    let tx1 = await cm.getSubjectConsents({from: dataSubject});

    assert.equal(tx1.length, 1, "consent was not created...");
  });

  it('get consents for swarmHash', async () => {
    // getConsentsFor(bytes32 swarmHash) public view returns (Consent[] memory)

    let tx1 = await cm.getConsentsFor(swarmHash1);

    assert.equal(tx1.length, 1, "consent was not created...");    
  });

  it('user signs consent', async () => {
    // signUser(bytes32 h, uint8 v, bytes32 r, bytes32 s)
    let tx1 = await cm.getUserConsents({from: dataUser});
    let con = await Consent.at(tx1[0]);

    let msg = tx1[0];
    let h = web3.utils.sha3(msg);

    // let sigg = await web3.eth.sign(h, dataUser);

    const sigg = EthCrypto.sign(
        privateKeyAcc0,
        h
    );

    const signer = EthCrypto.recover(
        sigg, // signature
        h // message hash
    );

    assert.equal(signer, accounts[0], "sig does not match signer");

    var sig = sigg.slice(2);
    var v = web3.utils.toDecimal(sig.slice(128, 130));    
    var r = `0x${sig.slice(0, 64)}`;
    var s = `0x${sig.slice(64, 128)}`

    let tx5 = await con.isUserSigned();

    assert.equal(tx5, false, "consent was not yet signed by user");
    console.log('t', h, v,r ,s)
    let tx2 = await con.signUser(h, v, r, s);

    let tx6 = await con.isUserSigned();

    assert.equal(tx6, true, "consent was not signed by user");    
  });
  
  it('subject signs consent', async () => {
    // signSubject(bytes32 h, uint8 v, bytes32 r, bytes32 s)
    let tx1 = await cm.getSubjectConsents({from: dataSubject});
    let con = await Consent.at(tx1[0]);

    let msg = tx1[0];
    let h = web3.utils.sha3(msg);

    const sigg = EthCrypto.sign(
        privateKeyAcc1,
        h
    );

    let sig = sigg.slice(2);
    let v = web3.utils.toDecimal(sig.slice(128, 130));    
    let r = `0x${sig.slice(0, 64)}`;
    let s = `0x${sig.slice(64, 128)}`

    let tx5 = await con.isSubjectSigned();
    assert.equal(tx5, false, "consent was not yet signed by subject");    

    let tx2 = await con.signSubject(h, v, r, s);

    let tx6 = await con.isSubjectSigned();

    assert.equal(tx6, true, "consent was not signed by subject");    
  });


  it('subject signs consent', async () => {
    // signSubject(bytes32 h, uint8 v, bytes32 r, bytes32 s)
    let tx1 = await cm.getSubjectConsents({from: dataSubject});
    let con = await Consent.at(tx1[0]);

    let tx5 = await con.isSigned();

    assert.equal(tx5, true, "consent was not signed");    
  });

  it('update existing consents with new location', async () => {
    // updateConsent(Consent consent, bytes32 swarmLocation) public returns (Consent)

    let tx1 = await cm.getSubjectConsents({from: dataSubject});

    // let con = await Consent.at(tx1[0]);

    // console.log(con);

    let tx2 = await cm.updateConsent(tx1[0], swarmHash2, {from: dataSubject});

    // let tx3 = await cm.getConsentsFor(swarmHash1);
    // let tx4 = await cm.getConsentsFor(swarmHash2);

    // assert.equal(tx3.length, 0, "consent was not updated...");
    // assert.equal(tx4.length, 1, "consent was not updated...");

    // let tx5 = await con.swarmHash();

    
    let consents = await cm.getSubjectConsents({from: dataSubject});
    
    // console.log(consents)
    
    let consent = await Consent.at(consents[0]);
    
    let consentStatus = await consent.status();
    
    // console.log(consentStatus);
    
    let newConsentAddress = await consent.updatedConsent();
    
    // console.log(newConsentAddress);
    
    let updatedConsent = await Consent.at(newConsentAddress);
    
    let swarmHash3 = await updatedConsent.swarmHash();
    
    assert.equal(swarmHash3, swarmHash2, "consent was not updated...");

  });  

  it('remove consent (only data subject)', async () => {
    // revokeConsent() 
    let tx1 = await cm.getSubjectConsents({from: dataSubject});
    let con = await Consent.at(tx1[0]);

    let tx2 = await con.isValid();
    assert.equal(tx2, true, "consent was not valid...");    

    let tx3 = await con.revokeConsent({from: dataSubject});
    let tx4 = await con.isValid();

    assert.equal(tx4, false, "consent was not revoked...");    
  });  
});