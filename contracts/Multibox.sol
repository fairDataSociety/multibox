/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */

/*
  so how we tackle access rights? 
  upon creation root is pupulated with common folders, 
  Initial folder structure is mapped 
     root      = newFolder(0); // the root of all, onlyOwner c7f5bbf5fe95923f0691c94f666ac3dfed12456cd33bd018e7620c3d93edd5a6
     shared    = addFolder(root, 0x23e642b7242469a5e3184a6566020c815689149967703a98c0affc14b9ca9b28); // only those that was shared with
     dataReceipt  = addFolder(root, 0x1d261cf1849d7042d71f91ae5de9f8e1102f872f83bef6add64509a927939609); // only owner r/w or those shared with
     incoming  = addFolder(root, 0xe723d028f3a255c87f4d0ff2d83c484a5a279f9791d3fbd87348df86ad478196); // unknown can add, but not read
     common    = addFolder(root, 0xf7c93b517d753615c49ea5b8b1ea3d75e9d75be99691bcf066226dc260a704be); // everyone r, owner w             
     temporary = addFolder(root, 0xc96eea3628fe2bbedfaf37cbf7a7c196aa346555e7b0dd60cea44a5319b17945); // everyone r/w   
*/
/*
      privateNodeId      = addFolder(rootNodeId, 0x69ebce02fbffacce50622356b97cc93a78f17feb5bf8e8ccacbdb7032e3162dc); // none can r/w
      publicNodeId       = addFolder(rootNodeId, 0x7e00625d1d39ffe13a119d9085848880ad5ccd078e38677f3a705653326d44ed); 
      unrestrainedNodeId = addFolder(rootNodeId, 0xd0e98c61c165756dc6a3294835afbb596b332b2a27061c997163e623939c6cc0); 
      
      setNodeAccess(publicNodeId, address(0x0), 1); // everyone can read, but not write
      setNodeAccess(sharedNodeId, address(0x0), 3); // unknown can add, but not read 
      setNodeAccess(unrestrainedNodeId, address(0x0), 2); // all can read all can write
*/

// DONE: prepare events, 
// TODO: method to move key/value from nodeId to new nodeId 
// TODO: add nodeId from other kvt, if its possible to do cross-contract node sharing ...  else write additional contract to hold shared data 
//

 pragma solidity ^0.5.0;
 contract Owned {
    address payable public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    /// @notice The Constructor assigns the message sender to be `owner`
    constructor () public { owner = msg.sender; }
    function changeOwner(address payable _newOwner) public onlyOwner { owner = _newOwner; }
}

contract KeyValueTree is Owned {
    mapping(bytes32 => bytes32) internal folderNodes; // map of folder to NodeId

    mapping(bytes32 => uint256) folderIndex; // map of folder to index (starts with 1, not 0!!)
    bytes32[] folders; // all folder roots

    mapping(bytes32 => mapping(bytes32 => bytes32[])) internal keyFolderValues; // feeds by sender by folder
    
    // folder time to live (disapearing feeds / messages)
    mapping(bytes32 => Node) internal Nodes; // NodeId to node
    mapping(bytes32 => bytes32) internal nodeIdToFolder; // nodeIds to protocol 

    // AccessRights
    // contains 0x0 = 1, everyone can read/write
    // contains 0x0 = 1, everyone can read/write
    // contains 0x0 = 0, none onlyOwner
    // contains address = -1, address is forbiden to 
    // contains address =  0, address is forbiden to 
    // contains address =  1, address can read
    // contains address =  2, address can read/write
    // contains address =  3, address can write but can not read
    // contains address =  4, address can overwrite existing address feed 
    struct Node {
        bool      isNode;
        bytes32   parent;
        uint      index;
        // consider putting protocol info in a node 
        mapping(address => int) canAccess;
        
        mapping(bytes32 => bytes32) valuesMap;
        bytes32[] keys;
        bytes32[] values;

        // child nodes
        bytes32[] children;  
    }
    
    event NodeAdded(bytes32);
    event NodeRemovedChild(uint256);
    event NodeAddChild(bytes32);
    event NodeAccessChange(bytes32,address,int);
    event NodeDelete(bytes32 nodeId, bytes32 folder);
    event AddFolder(bytes32 nodeId, bytes32 folder);
    event KeyValueSet(bytes32 nodeId, bytes32 key, bytes32 value);
    event KeyValueSetFolder(bytes32 nodeId, bytes32 folder);
    event OverwriteKeyValue(bytes32 nodeId, uint256 index, bytes32 key, bytes32 value);
    event RemoveKeyValue(bytes32 nodeId, uint256 index, bytes32 key, bytes32 value);
    
    function isNode(bytes32 nodeId) public view returns(bool)  {
        return Nodes[nodeId].isNode;
    }
    function getNodeChildrenCount(bytes32 nodeId) public view returns(uint childCount) {
        return Nodes[nodeId].children.length;
    }
    function getNodeChildAt(bytes32 nodeId, uint index) public view returns(bytes32 childId) {
        return Nodes[nodeId].children[index];
    }
    function getNodeChildren(bytes32 nodeId) public view returns(bytes32[] memory childrenId) {
        return Nodes[nodeId].children;
    }
    function removeChildAt(bytes32 nodeId, uint256 index) public returns (bool) {
         // removes children node from nodeId, not best way as it does reordering 
         if(!canWrite(nodeId, msg.sender)) return false;  // can write to node that is supposed to be deleted?

         Node storage node = Nodes[nodeId];
         
         if(!canWrite(node.children[index], msg.sender)) return false; // can write to node that is supposed to be deleted?
         
         uint last = node.children.length-1; // last child in the list
         uint idx = Nodes[node.children[last]].index;
         
         node.children[index] = node.children[last];
         delete node.children[last];
         node.children.length--;
         
         Nodes[node.children[last]].index = idx; // swap index
         
         emit NodeRemovedChild(index);
         return true;
    }    
    function addNode(bytes32 nodeId, bytes32 folder) internal returns(bytes32 newId) {
        if(!isNode(nodeId) && nodeId > 0) revert(); // zero is a new root node
        newId = keccak256(abi.encodePacked(nodeId, msg.sender, block.number, folder));

        Node memory node;
        node.parent = nodeId;
        node.isNode = true;
        
        if(nodeId>0) {
            node.index = addChildNode(nodeId,newId);
        }
        
        Nodes[newId] = node;
        emit NodeAdded(newId);
        return newId;
    }
    function addChildNode(bytes32 nodeId, bytes32 childId) private returns(uint index) {
        emit NodeAddChild(childId);
        return Nodes[nodeId].children.push(childId) - 1;
    }
    
    uint version;
    // should these be public, or private? and accessed through methods that also check accessRights ? 
    bytes32 public rootNodeId; // root of tree
    bytes32 public sharedNodeId; // incoming node id
    
    function getRoot() public view returns (bytes32) { return rootNodeId; }
    function getShared() public view returns (bytes32) { return sharedNodeId; }
    
    // constructor
    constructor(address payable _owner) public {
      version = 1;
      owner = _owner;         
      rootNodeId         = addNode(0, 0xc7f5bbf5fe95923f0691c94f666ac3dfed12456cd33bd018e7620c3d93edd5a6); // the root of all, onlyOwner r/w  c7f5bbf5fe95923f0691c94f666ac3dfed12456cd33bd018e7620c3d93edd5a6
      sharedNodeId       = addFolder(rootNodeId, 0x23e642b7242469a5e3184a6566020c815689149967703a98c0affc14b9ca9b28);
      // setNodeAccess(sharedNodeId, address(0x0), 3); // unknown can add, but not read 
    }
    
    function getVersion() public view returns (uint) {
         return version;
     }
    
    function setNodeAccess(bytes32 nodeId, address addr, int rights) /*onlyOwner*/ public returns (int) {
       //if(msg.sender!=owner) return -1;
       if(addr==owner) return 2; // owner always has r/w access, this is needed so one can not bloat mapping with owner address
       if(!canWrite( nodeId, msg.sender)) return -1;

       emit NodeAccessChange(nodeId,addr,rights);
       Nodes[nodeId].canAccess[addr] = rights;
       return rights;
    }
    function canRead(bytes32 nodeId, address addr) public view returns (bool) {
         if(!isNode(nodeId)) return false;
         if(addr==msg.sender) return true;
         
         Node storage n = Nodes[nodeId];
         if(n.canAccess[addr] == -1)  return false;  //address is blacklisted 
         if(n.canAccess[address(0x0)] == 3) return false; //none can read
         if(n.canAccess[address(0x0)] > 0)  return true;  //everyone can access
         return n.canAccess[addr]>0;
     }
    function canWrite(bytes32 nodeId, address addr) public view returns (bool) {
         if(!isNode(nodeId)) return false;
         if(addr==msg.sender) return true;
         
         Node storage n = Nodes[nodeId];
         if(n.canAccess[addr] == -1)  return false;  //address is blacklisted 
         if(n.canAccess[address(0x0)] > 1) return true; //everyone can write
         return n.canAccess[addr]>1;
     }
    function canOverwrite(bytes32 nodeId, address addr) public view returns (bool) {
         if(!isNode(nodeId)) return false;
         if(addr==msg.sender) return true;
         Node storage n = Nodes[nodeId];
         
         if(n.canAccess[addr] == -1)  return false;  //address is blacklisted 
         if(n.canAccess[address(0x0)] > 3) return true; //everyone can overwrite
         return n.canAccess[addr] > 3; // yes you can overwrite
     }
    ///////////////////////////////////////////////////////////////////////////////////////////       
    function deleteNode(bytes32 nodeId) public returns (bool) {
        if(!canWrite(nodeId, msg.sender)) return false;
        
        bytes32 folder = nodeIdToFolder[nodeId];
        if(folder==0x0) return false; // no mapping to folder

        Node storage node = Nodes[nodeId];
        if(removeChildAt(node.parent, node.index)) 
        {
            uint256 index = folderIndex[folder]; 
            if(index!=0)
            {
                folderNodes[folder] = 0x0;
                folderIndex[folder] = 0;
        
                folders[index] = folders[folders.length-1];
                delete folders[folders.length-1];
                folders.length--;
                
                emit NodeDelete(nodeId, folder);
                return true;
            }
        }
        return false;
    }     
     
    // problem is that subFolder is added to folderNodes mapping
    // this means subFolder can be only one and must be unique 
    // which in turn means that we can't have same subFolder in different parent protocols
    // add subProtocol to parentProtocol (protocolNodeId)
    // so if if parent is bin, then add subFolder as "/bin/subFolderName" 
    // returns nodeId of new subFolder or 0x0 if error 
    function addFolder(bytes32 parentNodeId, bytes32 subFolder) public returns (bytes32) {
        bytes32 parentId = parentNodeId;
        if(!isNode(parentId)) // parentNode is not a node, then write to root
           parentId = rootNodeId;
        
        if(!canRead(parentId, msg.sender)) // no read permission for parent
           parentId = sharedNodeId;

        bytes32 subNode = folderNodes[subFolder]; // "/bin" -> hash
        if(subNode != 0) // if subProtocol exists as protocol, then fail
        {
            if(!canRead(subNode, msg.sender)) // no read permission 
               return 0x0;
               
            return subNode;
        }
        
        if(!canWrite(parentId, msg.sender)) // no write permission
           return 0x0;
        
        bytes32 newNodeId = addNode(parentId, subFolder); // add child to parent

        folderNodes[subFolder] = newNodeId; 
        folderIndex[subFolder] = folders.push(subFolder);
        
        nodeIdToFolder[newNodeId] = subFolder; // we need mapping to folder from nodeId
        
        emit AddFolder(newNodeId, subFolder);
        
        if(msg.sender!=owner)
          setNodeAccess(newNodeId, msg.sender, 2); // give r/w access to creator of node
           
        return newNodeId; 
    }
    ///////////////////////////////////////////////////////////////////////////////////////////      
    // setKeyValue, will suceed only when no such key with value exist
    function setKeyValueFolder(bytes32 folder, bytes32 key, bytes32 value) public returns (bool) {
         bytes32 targetNode = folderNodes[folder];
         
         if(targetNode==0) {// folder does not exist in mapping to all folder
            bytes32 makeSubFolderIn = sharedNodeId; // everything goes to incoming
            if(msg.sender == owner) // owner can create in root 
               makeSubFolderIn = rootNodeId;
              
            targetNode = addFolder(makeSubFolderIn, folder);
         }
         emit KeyValueSetFolder(targetNode, folder);
         
         return setKeyValue(targetNode, key, value);
    }
    function setKeyValue(bytes32 nodeId, bytes32 key, bytes32 value) public returns (bool) {
         if(!canWrite(nodeId, msg.sender)) // no read permission for parent
           return false;
         
         Node storage node = Nodes[nodeId];
         bytes32 folder = getFolder(nodeId);
         if(node.valuesMap[key] == 0x0) // no such value yet
         {
            node.keys.push(key);
            node.values.push(value); 
            node.valuesMap[key] = value;
            keyFolderValues[key][folder].push(value);
            emit KeyValueSet(nodeId, key, value);
            return true; 
         } 
         
         keyFolderValues[key][folder].push(value);
         return false;
     }
    ///////////////////////////////////////////////////////////////////////////////////////////       
    
    ///////////////////////////////////////////////////////////////////////////////////////////
    // getKeys 
    function getKeys(bytes32 nodeId) view public returns (bytes32[] memory) {
         bytes32[] memory ret;
         if(!canRead(nodeId, msg.sender)) return ret;

         return Nodes[nodeId].keys;
     }
    // get num keys
    function getKeysCount(bytes32 nodeId) view public returns (uint) {
         if(!canRead(nodeId, msg.sender)) return 0;
             
         return Nodes[nodeId].keys.length;
     }
    // get key at
    function getKeyAt(bytes32 nodeId, uint index) view public returns (bytes32) {
         if(!canRead(nodeId, msg.sender)) return 0x0;
             
         return Nodes[nodeId].keys[index];
     }
     
    /////////////////////////////////////////////////////////////////////////////////////////// 
    // getValues 
    function getValue(bytes32 nodeId, bytes32 key) public view returns (bytes32) {
         if(!canRead(nodeId, msg.sender)) return 0x0;
             
         return Nodes[nodeId].valuesMap[key];
    }
    // get num values
    function getValuesCount(bytes32 nodeId) view public returns (uint) {
         if(!canRead(nodeId, msg.sender)) return 0;
             
         return Nodes[nodeId].values.length;
     }
    // get value at  
    function getValueAt(bytes32 nodeId, uint index) view public returns (bytes32) {
         if(!canRead(nodeId, msg.sender)) return 0x0;
             
         return Nodes[nodeId].values[index];
     }
    
    ///////////////////////////////////////////////////////////////////////////////////////////
    // overwrite in folder with new sender and new feed
    function overwriteKey(bytes32 nodeId, uint index, bytes32 key, bytes32 newValue) public returns (bool) {
        if(!canOverwrite(nodeId, msg.sender)) return false;
        
        Node storage node = Nodes[nodeId];
        if(index<node.values.length) // no such feed yet
        {
            bytes32 prevKey = node.keys[index]; // where is previous
            node.valuesMap[prevKey] = 0x0; // set it to null 
            
            node.keys[index] = key;
            node.values[index] = newValue; 
            node.valuesMap[key] = newValue; //
            bytes32 folder = getFolder(nodeId);
            keyFolderValues[key][folder].push(newValue);
            
            emit OverwriteKeyValue(nodeId,index,key,newValue);
            return true;
        }        
        return false;
     }
    // remove key
    function removeKeyAt(bytes32 nodeId, uint256 index) public returns (bool) {
         if(!canWrite(nodeId, msg.sender)) return false; 
         
         Node storage node = Nodes[nodeId];
         
         bytes32 atKey = node.keys[index];
         bytes32 preValue = node.values[index];
         require(atKey!=0x0); // node has no sender at index 
         
         node.valuesMap[atKey] = 0x0; // clear sender         
         
         node.keys[index] = node.keys[node.keys.length-1];
         delete node.keys[node.keys.length-1];
         node.keys.length--;
         
         node.values[index] = node.values[node.values.length-1];
         delete node.values[node.values.length-1];
         node.values.length--;
         
         emit RemoveKeyValue(nodeId, index, atKey, preValue);
         return true;
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////      
    function getNodeId(bytes32 folder) view public returns (bytes32) { // will get protocol node address
         bytes32 nodeId = folderNodes[folder];
         if(nodeId==0) // does not exist
         {
            if(!canRead(rootNodeId, msg.sender)) 
               return 0x0;        
            else     
               return rootNodeId;
         }        

         return folderNodes[folder];
    }
    ///////////////////////////////////////////////////////////////////////////////////////////      
    function getFolderIndex(bytes32 folder) view public returns (uint256) { // will get protocol node address
         return folderIndex[folder];
     }
    // get folder by nodeId
    function getFolder(bytes32 nodeId) view public returns (bytes32) {
         
         if(nodeIdToFolder[nodeId]==0) // does not exist
         {
            if(!canRead(rootNodeId, msg.sender)) 
                return 0x0;        
            else     
                return rootNodeId;
         }        
         
         if(!canRead(nodeId, msg.sender)) return 0x0;           
         return nodeIdToFolder[nodeId];
     }

    // ONLY OWNERS CAN ACCESS COMPLETE INFORMATION
    ///////////////////////////////////////////////////////////////////////////////////////////      
    // get all values ever, chronologically, never gets deleted, only added
    function getFolderValuesForAKey(bytes32 folder, bytes32 key) onlyOwner view public returns (bytes32[] memory) {
       return keyFolderValues[key][folder];
    }
     
    ///////////////////////////////////////////////////////////////////////////////////////////      
    function getAllFolders() onlyOwner view public returns (bytes32[] memory) { // get all folder
     return folders;
    }     
    function getAllFoldersCount() onlyOwner view public returns (uint256) { // get num of folder
     return folders.length;
    }
    function getFolderAt(uint256 idx) onlyOwner view public returns (bytes32) { // get folder by idx
     return folders[idx];
    }
    ///////////////////////////////////////////////////////////////////////////////////////////
    
    // fallback function to accept ETH into contract.
    function () external payable { }
    // allow owner to remove funds  
    function removeFunds() onlyOwner public {
        owner.transfer(address(this).balance);
    }    
}

contract Multibox is Owned
{
    uint version;
    bool public initialized=false; 
    // addresses of roots     
    KeyValueTree[] roots; 
    
    event Initialized();
    event RootCreated(KeyValueTree);
    event RootAdded(KeyValueTree);
    event RootFailedNoOwner(address sender, address  owner);
    event RootRemoved(uint256);
    event RootRevoked(uint256);
    event FundsRemoved(uint256);
    
    event AccessRequested(address, Multibox, KeyValueTree, bytes32);
    event AccessRequestFail(address, Multibox, KeyValueTree, bytes32 nodeId, bool canOwnerWrite);
    event AccessRequestFailNotOwner(address kvtOwner, address multiboxOwner); 
    event AccessGiven(address, address to);
    
    constructor() public {
        version = 1;
        initialized=false;
    }
    
    function init() public returns (KeyValueTree) {
        KeyValueTree a; 
        if(!initialized)
            a = createRoot(owner);
        
        if(!initialized) 
           emit Initialized(); 
           
        initialized=true;
        return a;
    }
    
    // any one can create new root, but ownership will belong to owner of multibox, 
    // while r/w of shared node can be set to whoHasReadWriteRights
    function createRoot(address whoHasReadWriteRights) public returns (KeyValueTree) {
        KeyValueTree kvt = new KeyValueTree(owner);
        if(!initialized)
          kvt.setNodeAccess(kvt.getShared(), whoHasReadWriteRights, 3); // first root shared node can anyone write to, but can't read from
        else 
          kvt.setNodeAccess(kvt.getShared(), whoHasReadWriteRights, 2); // whoHasReadWriteRights r/w 
          
        emit RootCreated(kvt);  
        return addRoot(kvt);
    }
    function getRoots() public view returns (KeyValueTree[] memory) {
        return roots;
    }
    function getRootsCount() public view returns (uint256) {
        return roots.length;
    }
    function getRootAt(uint256 index) public view returns (KeyValueTree) {
        return roots[index];
    }
    // others can add KeyValueTrees (but need to set access rights by themselfs)
    function addRoot(KeyValueTree kvt) public returns (KeyValueTree) {
        
        if(kvt.owner() != msg.sender) // not owner of tree? can't move then 
        {
            emit RootFailedNoOwner(msg.sender, kvt.owner());
            return KeyValueTree(0x0);
        }

        roots.push(kvt);
        emit RootAdded(kvt);  
        return kvt;
    }
    // owner can remove any root except 0 
    function removeRoot(uint256 index) onlyOwner public returns (uint256) {
        if(index==0) return 0; // fail cant NEVER remove root
        
        roots[index] = roots[roots.length-1];
        delete roots[roots.length-1];
        roots.length--;
        emit RootRemoved(index);
        return roots.length;
    }
    // others can remove their trees 
    function revokeRoot(uint256 index) public returns (uint256) {
        KeyValueTree kvt = roots[index];
         
        if(index==0) return 0; // fail cant NEVER remove root
        if(kvt.owner() == msg.sender) // not owner of tree? can't move then 
           return 0;
        
        roots[index] = roots[roots.length-1];
        delete roots[roots.length-1];
        roots.length--;
        emit RootRevoked(index);
        return roots.length;
    }
    
    // fallback function to accept ETH into contract.
    function () external payable {
    }
    // allow owner to remove funds  
    function removeFunds() onlyOwner public {
        emit FundsRemoved(address(this).balance);
        owner.transfer(address(this).balance);
    }
    
    // ok so maybe this should be on Multibox level, multibox,kvt, nodeId
    DataRequestEscrow[] accessRequests;
    mapping(address => uint256) accessRequestsIndex; // map of folder to index (+1)
    
    function requestAccess(KeyValueTree kvt, bytes32 nodeId) public returns(DataRequestEscrow)
    {
        DataRequestEscrow dr;
        bool canWrite = kvt.canWrite(nodeId, owner);
        if(kvt.owner()!=this.owner())
        {
            emit AccessRequestFailNotOwner(kvt.owner(), this.owner());
            return dr;
        }
        if(canWrite)
        {
            dr = new DataRequestEscrow(msg.sender, this, kvt, nodeId); 
            accessRequestsIndex[address(dr)] = accessRequests.push(dr);
            emit AccessRequested(msg.sender, this, kvt, nodeId);
            return dr;
        }
        
        emit AccessRequestFail(msg.sender, this, kvt, nodeId, canWrite);
        return dr;
    }
    function allowAccess(DataRequestEscrow dr) public onlyOwner 
    {
        uint256 index = accessRequestsIndex[address(dr)];
        if(index!=0) 
        {
            if(dr.approve())
            {
                emit AccessGiven(address(dr), dr.whoRequester());
                
                accessRequestsIndex[address(dr)] = 0;
                
                accessRequests[index-1] = accessRequests[accessRequests.length-1];
                delete accessRequests[accessRequests.length-1];
                accessRequests.length--;
                
                dr.finalize(); // destroy contract, funds are moved to multibox.owner
            }
        }
        dr.denyApproval();
    }
    function amountAvailable(DataRequestEscrow dr) public view returns(uint balance)
    {
        return address(dr).balance;
    }
}

// kvt, nodeid
// what we want: we want to assure that if addr1 gives data to addr2, addr2 will really pay 
// like escrow:
// 1. alice request data kvt,nodeid(,key,value) from bob
// 2. bob sets price
// 3. alice pays price to escrow
// 4. bob transfers knt,nodeid,key,value to alice
// 5. bob takes the money

contract DataRequestEscrow {
    Multibox multibox;
    KeyValueTree kvt; 
    bytes32 nodeId; 

    address payable requester;

    modifier onlyOwnerMultibox() {
        require(msg.sender == multibox.owner());
        _;
    }
    
    constructor(address payable whoIsRequesting, Multibox mb, KeyValueTree keyValueTree, bytes32 targetNodeId) public
    {
        requester = whoIsRequesting;
        multibox = mb;
        kvt = keyValueTree;
        nodeId = targetNodeId;
    }

    function deposit() external payable {
        require(msg.sender==requester);
        require(msg.value > 0);
    }
    
    function whoRequester() onlyOwnerMultibox public view returns(address payable)
    {
        return requester;
    }

    function approve() onlyOwnerMultibox external returns (bool) {
        if(kvt.isNode(nodeId))
        {
            int readRights = kvt.setNodeAccess(nodeId, requester, 1); // give read permission 
            if(readRights==1) {
               return true;
            }
        }
        return false;
    }
    function finalize() onlyOwnerMultibox external 
    {
        selfdestruct(multibox.owner()); // this failed, give funds back
    }
    function denyApproval() onlyOwnerMultibox external 
    {
        selfdestruct(requester); // this failed, give funds back
    }
    function abortApproval() external 
    {
        require(msg.sender==requester);
        selfdestruct(requester); // this failed, give funds back
    }
}