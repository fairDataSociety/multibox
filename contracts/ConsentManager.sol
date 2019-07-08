// TEX 05.06.2019
pragma solidity ^0.5.0;
//pragma experimental ABIEncoderV2;

contract ConsentManager {
    event SignaturesRequired(Consent consent, address dataUser, address dataSubject);
    event ConsentUpdated(Consent consent, Consent withConsent);
    event ConsentUpdate(address sender, address payable dataSubject, address payable dataUser); 
    
    /////////////////////////////////////////////////////////////////
    // these could be omited 
    /*address[] dataSubjects;
    address[] dataUsers;
    mapping(address => uint256) internal existingDataSubject;
    mapping(address => uint256) internal existingDataUsers; */
    /////////////////////////////////////////////////////////////////
    
    mapping(address => Consent[]) internal userConsents; 
    mapping(address => Consent[]) internal subjectConsents;
    mapping(bytes32 => Consent[]) internal consentsOnSwarm; 
    
    
    function createConsent(address payable dataUser, address payable dataSubject, bytes32 swarmLocation) public returns (Consent) {
        Consent consent = new Consent(address(this), dataUser, dataSubject, swarmLocation);
        
        addConsent(consent);
        
        consentsOnSwarm[swarmLocation].push(consent);
        
        emit SignaturesRequired(consent, dataUser, dataSubject);
        return consent;
    }
    
    function updateConsent(Consent consent, bytes32 swarmLocation) payable public returns (Consent) {
        emit ConsentUpdate(msg.sender, consent.dataSubject(), consent.dataUser());
        require(msg.sender==address(consent.dataSubject()) || msg.sender==address(consent.dataUser()));

        Consent newConsent = new Consent(address(this), consent.dataUser(), consent.dataSubject(), swarmLocation);
        
        consent.updateConsent(newConsent);
        //address(consent).call(abi.encodeWithSignature("updateConsent(Consent)", address(consent)));
        consentsOnSwarm[swarmLocation].push(consent);
        
        emit ConsentUpdated(consent, newConsent);
        emit SignaturesRequired(newConsent, consent.dataUser(), consent.dataSubject());
        return newConsent;
    }
    
    // others can add KeyValueTrees (but need to set access rights by themselfs)
    function addConsent(Consent consent) private returns (Consent) {

        userConsents[consent.dataUser()].push(consent);
        subjectConsents[consent.dataSubject()].push(consent);
        
        return consent;
    }
    
    function getUserConsents() public view returns (Consent[] memory) {
        return userConsents[msg.sender];
    }
    function getSubjectConsents() public view returns (Consent[] memory) {
        return subjectConsents[msg.sender];
    }
    function getConsentsFor(bytes32 swarmHash) public view returns (Consent[] memory) {
        return consentsOnSwarm[swarmHash];
    }
}

contract Consent {

    //event LogA(address A, address B);
    event UpdatingConsent(address sender, address payable dataSubject, Consent consent, address origin); 

    function () external payable {    }
    function removeFunds()  public { 
        require(msg.sender == dataSubject);
        dataSubject.transfer(address(this).balance); 
    }

    constructor(address consentManager, address payable dataUserAddress, address payable dataSubjectAddress, bytes32 swarmLocation) public {
        consentMan = consentManager;
        status = ConsentStatus.AWAITINGSIGNATURE; 
        swarmHash = swarmLocation;
        
        dataUser = dataUserAddress;
        dataSubject = dataSubjectAddress;
        userSigned = false;
        subjectSigned = false;
        //validUntil = block.number + (365 * 24 * 60 * 60); // one year until valid
    }
    
    enum ConsentStatus {AWAITINGSIGNATURE,ACTIVE,EXPIRED,REVOKED_SUBJECT, REVOKED_USER}
    ConsentStatus public status;
    address public consentMan;
    
    bytes32 public swarmHash;
    address payable public dataUser;
    address payable public dataSubject;
    //uint256 public validUntil;
    
    bool private userSigned;
    bool private subjectSigned;
    
    Consent public updatedConsent;

    function revokeConsent() public returns (ConsentStatus) {
        require(msg.sender==dataSubject || msg.sender==dataUser);
        if(msg.sender==dataSubject)
           status = ConsentStatus.REVOKED_SUBJECT;
        else
           status = ConsentStatus.REVOKED_USER;  
    }
    
    function updateConsent(Consent consent) public returns (ConsentStatus) {
        emit UpdatingConsent(msg.sender, dataSubject, consent, tx.origin);
        require(msg.sender==consentMan);
        //require(msg.sender==dataSubject);
        status = ConsentStatus.EXPIRED;  
        updatedConsent = consent;
    }
    
    function isValid() public view returns (bool) {
        /*if(block.number>validUntil)
        {
           status = ConsentStatus.EXPIRED;  
           return false;
        }*/
           
        return status==ConsentStatus.ACTIVE;
    }

    function isSigned() public view returns (bool) { return userSigned && subjectSigned; }
    function isUserSigned() public view returns (bool) { return userSigned;  }
    function isSubjectSigned() public view returns (bool) { return subjectSigned;  }
    
    // transition to ACTIVE only when both parties signed this consent
    function transitionToActive() public returns (ConsentStatus) { 
        require(status == ConsentStatus.AWAITINGSIGNATURE);
        if(isSigned()) 
           status = ConsentStatus.ACTIVE;
           
        return status;
    }

    function signUser(bytes32 h, uint8 v, bytes32 r, bytes32 s) public returns (address) {
        require(userSigned==false);
        userSigned = signForRaw(dataUser, h,v,r,s);
        transitionToActive();
    }
    function signSubject(bytes32 h, uint8 v, bytes32 r, bytes32 s) public returns (address) {
        require(subjectSigned==false);
        subjectSigned = signForRaw(dataSubject, h,v,r,s);
        transitionToActive();
    }
    
    // function signFor(address payable forParty, bytes32 h, uint8 v, bytes32 r, bytes32 s) private pure returns (bool) {
    //     bytes memory prefix = "\x19Ethereum Signed Message:\n32";

    //     bytes32 dataHash = keccak256(abi.encodePacked(prefix, h));
    //     address addr = ecrecover(dataHash, v, r, s);
        
    //     return (addr == forParty);
    // }

    function signForRaw(address payable forParty, bytes32 h, uint8 v, bytes32 r, bytes32 s) private pure returns (bool) {
        address addr = ecrecover(h, v, r, s);
        return (addr == forParty);
    }
}