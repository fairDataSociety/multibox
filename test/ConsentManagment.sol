//const Web3 = require('web3');
//const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:9545'));


const ConsentManager = artifacts.require("ConsentManager");
const Consent = artifacts.require("Consent");


contract('ConsentManager', (accounts) => {
    it('deploy master consent manager', async () => {
        const cm = await ConsentManager.deployed();
    });
    
	it('create consent', async () => {
		// createConsent(address payable dataUser, address payable dataSubject, bytes32 swarmLocation) public returns (Consent)
    });

	it('get user consents', async () => {
		// getUserConsents() public view returns (Consent[] memory)
    });
	it('get subject consents', async () => {
		// getSubjectConsents() public view returns (Consent[] memory) 
    });
	it('get consents for swarmHash', async () => {
		//  getConsentsFor(bytes32 swarmHash) public view returns (Consent[] memory)
    });

	it('update existing consents with new location', async () => {
		//  updateConsent(Consent consent, bytes32 swarmLocation) public returns (Consent)
    });
	
	///////////////////////////////////////////////////////////////////////////////
	// consent contract

	it('remove consent (only data subject)', async () => {
		// revokeConsent() 
    });

	it('update consent (only data subject) <- called from consent manager', async () => {
		// updateConsent(Consent consent) 
    });

	it('user signs consent', async () => {
		// signUser(bytes32 h, uint8 v, bytes32 r, bytes32 s)

		// check https://ethereum.stackexchange.com/questions/15364/ecrecover-from-geth-and-web3-eth-sign
		/* 
		    var instance = await Example.deployed()
			var msg = '0x8CbaC5e4d803bE2A3A5cd3DbE7174504c6DD0c1C'

			var h = web3.sha3(msg)
			var sig = web3.eth.sign(address, h).slice(2)
			var r = `0x${sig.slice(0, 64)}`
			var s = `0x${sig.slice(64, 128)}`
			var v = web3.toDecimal(sig.slice(128, 130)) + 27

			var result = await instance.testRecovery.call(h, v, r, s)
			assert.equal(result, address)
		*/
    });
	
	it('subject signs consent', async () => {
		// signSubject(bytes32 h, uint8 v, bytes32 r, bytes32 s)
    });
});