/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */

// A
     //   B 
     //   D
     // C
     //   B <-
     //   D 
     // 
     //

     // B, nodeId A.B, nodeId C.B 
     
     // hash1.hash2.hash3 
     
     // i.e.
     // 0
     // fairdrop (hash1) 
     // chattie (hash2)
     //   - forms 
     //   - payments
     //   - event (hash33)
     // calendar (hash3) 
     //   - todos 
     //   - event (hash33)
     // graphics
     //   - unity
     //   - houdini 
     //   - maya 
     // sport 
     //   - bracelet
     //      - fitbit 
     //      - nike
     // connections 
     // code
     //   - repos 
     //      - github 
     //      - gitlab 
     // data  
     //   - personal
     // bank
     //  - HSBC
     //   - request
     //   - 
     
     // hash3.hash33 <- calendar
     // hash33 <- all events 
     
     // so how we tackle access rights
     // upon creation root is pupulated with common folders, 
     // common folders: 
     // -- folders are mapped as linux fs 
     // /
     // /bin
     // /boot
     // /dev
     // /etc
     // /home
     // /lib
     // /lost+found
     // /media
     // /mnt
     // /opt
     // /proc
     // /root
     // /run
     // /sbin
     // /srv
     // /tmp
     // /var
     // exceptions:
     // /consents
     // /tokens
     // /disapearing
     

 pragma solidity ^0.5.0;
 contract Owned {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    /// @notice The Constructor assigns the message sender to be `owner`
    constructor () public { owner = msg.sender; }
    
    function changeOwner(address _newOwner) public onlyOwner { owner = _newOwner; }
}

 contract Multibox is Owned {
    mapping(bytes32 => bytes32) folderNodes; // map of folder to NodeId

    mapping(bytes32 => uint256) folderIndex; // map of folder to index
    bytes32[] folders; // all folder roots

    mapping(bytes32 => uint256) senderMap; // map of senders
    bytes32[] senders; // all senders
    
    mapping(bytes32 => mapping(bytes32 => bytes32[])) internal senderFolderFeeds; // feeds by sender by folder
    
    // AccessRights
    // if it contains 0x0 = 1, everyone can read/write
    // if it contains 0x0 = 0, none onlyOwner
    // if it contains address = 0, address is forbiden to 
    // if it contains address = 1, address can read
    // if it contains address = 2, address can read/write
    struct Node
    {
        bool      isNode;
        bytes32   parent;
        uint      index;
        // consider putting protocol info in a node 
        //AccessRights accessRights;
        mapping(address => int) canAccess;
        
        mapping(bytes32 => bytes32) feedsMap;
        bytes32[] feeds;
        bytes32[] senders;

        bytes32[] children;  // other nodes
    }
    
    // folder time to live (disapearing feeds / messages)
    mapping(bytes32 => Node) internal Nodes; // NodeId to node
    mapping(bytes32 => bytes32) internal NodeIdToFolder; // nodeIds to protocol 
    
    function isNode(bytes32 nodeId) public view returns(bool isIndeed)  {
        return Nodes[nodeId].isNode;
    }
    function getNodeCount(bytes32 nodeId) public view returns(uint childCount) {
        return Nodes[nodeId].children.length;
    }
    function getNodeAtIndex(bytes32 nodeId, uint index) public view returns(bytes32 childId) {
        return Nodes[nodeId].children[index];
    }
    function getNodeChildren(bytes32 nodeId) public view returns(bytes32[] memory childrenId) {
        return Nodes[nodeId].children;
    }
    function newFolder(bytes32 parent) internal returns(bytes32 newId) {
        if(!isNode(parent) && parent > 0) revert(); // zero is a new root node
        newId = keccak256(abi.encodePacked(parent, msg.sender, block.number));
        
        Node memory node;
        node.parent = parent;
        node.isNode = true;
        
        if(parent>0) {
            node.index = registerChild(parent,newId);
        }
        
        Nodes[newId] = node;
        return newId;
    }
    function registerChild(bytes32 parentId, bytes32 childId) private returns(uint index) {
        return Nodes[parentId].children.push(childId) - 1;
    }
    
    function removeSenderAt(bytes32 nodeId, uint256 index) public returns (bool) {
         if(!canAddressWrite(msg.sender, nodeId)) return false; 
         
         Node storage node = Nodes[nodeId];
         
         require(node.senders[index]!=0x0); // node has no sender at index 
         node.feedsMap[node.senders[index]] = 0x0; // clear sender         
         
         node.senders[index] = node.senders[node.senders.length-1];
         delete node.senders[node.senders.length-1];
         node.senders.length--;
         
         node.feeds[index] = node.feeds[node.feeds.length-1];
         delete node.feeds[node.feeds.length-1];
         node.feeds.length--;
         return true;
    }
    // removes children node from parentId
    function removeChildAt(bytes32 nodeId, uint256 index) public returns (bool) {
         if(!canAddressWrite(msg.sender, nodeId)) return false; 

         Node storage node = Nodes[nodeId];
         uint last = node.children.length-1; // last child in the list
         uint idx = Nodes[node.children[last]].index;
         
         node.children[index] = node.children[last];
         delete node.children[last];
         node.children.length--;
         
         Nodes[node.children[last]].index = idx; // swap index
         return true;
    }    
    
    
    uint256 version;
    bytes32 public root; // root of protocol trees
    bytes32 public shared; // root of shared folder
    bytes32 public consents; // root of consents folder
    bytes32 public common; // root of temporary folders
    bytes32 public incoming; // root of incoming folder
    bytes32 public temporary; // root of temporary folders

     /**
      * Constructor.
      */
     constructor() public {
         version = 1;
         
         root      = newFolder(0); // the root of all, onlyOwner c7f5bbf5fe95923f0691c94f666ac3dfed12456cd33bd018e7620c3d93edd5a6
         shared    = addFolder(root, 0x23e642b7242469a5e3184a6566020c815689149967703a98c0affc14b9ca9b28); // only those that was shared with
         consents  = addFolder(root, 0x1d261cf1849d7042d71f91ae5de9f8e1102f872f83bef6add64509a927939609); // only owner r/w or those shared with
         
         incoming  = addFolder(root, 0xe723d028f3a255c87f4d0ff2d83c484a5a279f9791d3fbd87348df86ad478196); // unknown can add, but not read
         common    = addFolder(root, 0xf7c93b517d753615c49ea5b8b1ea3d75e9d75be99691bcf066226dc260a704be); // everyone r, owner w             
         temporary = addFolder(root, 0xc96eea3628fe2bbedfaf37cbf7a7c196aa346555e7b0dd60cea44a5319b17945); // everyone r/w   

         setNodeAccess(incoming, address(0x0), 3); // unknown can add, but not read 
         setNodeAccess(common, address(0x0), 1); // everyone can read
         setNodeAccess(temporary, address(0x0), 2); // everyone read/write
     }
     function getVersion() public view returns (uint256) {
         return version;
     }
     
     function setNodeAccess(bytes32 nodeId, address addr, int rights) onlyOwner public returns (int) {
         if(Nodes[nodeId].isNode) {
            Nodes[nodeId].canAccess[addr] = rights;
            return Nodes[nodeId].canAccess[addr];
         }
         return 0;
     }
     function canAddressRead(address addr, bytes32 nodeId) public view returns (bool) {
         if(addr==msg.sender) return true;
         Node storage n = Nodes[nodeId];
         if(n.isNode) {
            if(n.canAccess[address(0x0)] == 3) return false; //none can read
            if(n.canAccess[address(0x0)] > 0)  return true;  //everyone can access
            return n.canAccess[addr]>0;
         }
         return false;
     }
     function canAddressWrite(address addr, bytes32 nodeId) public view returns (bool) {
         if(addr==msg.sender) return true;
         Node storage n = Nodes[nodeId];
         if(n.isNode) {
            if(n.canAccess[address(0x0)] > 1) return true; //everyone can write
            return n.canAccess[addr]>1;
         }
         return false;
     }

     // problem is that subFolder is added to folderNodes mapping
     // this means subFolder can be only one and must be unique 
     // which in turn means that we can't have same subFolder in different parent protocols
     // add subProtocol to parentProtocol (protocolNodeId)
     // hash(parentProtocol.subProtocol)  
     // so if if parent is bin, then and subFolder as "bin/subFolderName/" 
     // returns nodeId of new subFolder or 0x0 if error 
     function addFolder(bytes32 parentFolder, bytes32 subFolder) public returns (bytes32) {
        bytes32 parentNode = folderNodes[parentFolder];
        
        if(parentNode == 0) // if no such parent folder
           parentNode = root; // then parent is root 
           
        if(!canAddressRead(msg.sender, parentNode)) // no read permission for parent
           return 0x0;

        bytes32 subNode = folderNodes[subFolder];
        // there can be only ONE subprotocol, calculate subfolder hash with something like hash(parentName.subProtocolName)
        if(subNode != 0) // if subProtocol exists as protocol, then fail
        {
            if(!canAddressRead(msg.sender, subNode)) // no read permission 
               return 0x0;
               
            return folderNodes[subFolder];
        }

        if(!canAddressWrite(msg.sender, parentNode)) // no write permission
           return 0x0;
        
        folderIndex[subFolder] = folders.push(subFolder)-1;
        folderNodes[subFolder] = newFolder(parentNode); // add child to parent
        
        bytes32 newNodeId = folderNodes[subFolder];
        
        NodeIdToFolder[newNodeId] = subFolder; // we need mapping to folder from nodeId
        
        if(msg.sender!=owner)
          setNodeAccess(newNodeId, msg.sender, 2); // give r/w access to creator of node
           
        return newNodeId; 
     }

     ///////////////////////////////////////////////////////////////////////////////////////////      
     // so who can add newRequest and where ? 
     function newRequest(bytes32 folder, bytes32 sender, bytes32 feed) public returns (bool) {
         bytes32 targetNode = folderNodes[folder];
         
         if(targetNode==0) {// folder does not exist in mapping to all folder
            bytes32 makeSubFolderIn = incoming; // everything goes to incoming
            
            if(msg.sender == owner) // owner can create in root 
               makeSubFolderIn = root;
              
             targetNode = addFolder(makeSubFolderIn, folder);
         }
         
         if(!canAddressWrite(msg.sender, targetNode)) // no read permission for parent
           return false;
         
         if(senderMap[sender] == 0) { // if no such sender exits (only unique senders)
            senderMap[sender] = senders.push(sender)-1;
         }
         
         Node storage node = Nodes[targetNode];
         if(node.feedsMap[sender] == 0x0) // no such feed yet
         {
            node.senders.push(sender);
            node.feeds.push(feed); 
            node.feedsMap[sender] = feed;
         }
         
         senderFolderFeeds[sender][folder].push(feed);
         return true;
     }
     //
     function newRequest(bytes32 sender, bytes32 feed) public returns (bool) {
         return newRequest(incoming, sender, feed);
     }
     
     ///////////////////////////////////////////////////////////////////////////////////////////       
     function deleteFolder(bytes32 folder) public returns (bool)
     {
        bytes32 nodeId = folderNodes[folder];
         
        if(!canAddressRead(msg.sender, nodeId)) return false;
        if(!canAddressWrite(msg.sender, nodeId)) return false;

        Node storage node = Nodes[nodeId];
        if(removeChildAt(node.parent, node.index)) 
        {
            uint256 index = folderIndex[folder];
            //bytes32 newNodeId = folderNodes[folder];
            folderNodes[folder] = 0x0;
            folderIndex[folder] = 0x0;
    
            folders[index] = folders[folders.length-1];
            delete folders[folders.length-1];
            folders.length--;
            return true;
        }
        return false;
     }
     ///////////////////////////////////////////////////////////////////////////////////////////       
     
     ///////////////////////////////////////////////////////////////////////////////////////////       
     function getRequests(bytes32 folder) view public returns (bytes32[] memory) {
         if(folderNodes[folder]==0) // folder does not exist
             return Nodes[root].senders;
             
         return Nodes[folderNodes[folder]].senders;
     }
     function getRequest(bytes32 folder, bytes32 sender) public view returns (bytes32) {
         if(folderNodes[folder]==0) // folder does not exist         {
             return Nodes[root].feedsMap[sender];
             
         return Nodes[folderNodes[folder]].feedsMap[sender];
     }
     ///////////////////////////////////////////////////////////////////////////////////////////      
     function getFolderNodeAddress(bytes32 folder) view public returns (bytes32) { // will get protocol node address
         if(folderNodes[folder]==0) // protocol does not exist
             return root;     
             
         return folderNodes[folder];
     }
     function getFolderChildrenNodeIDs(bytes32 folderNodeId) view public returns (bytes32[] memory) { // will get protocol node address
         return Nodes[folderNodeId].children;
     }
     ///////////////////////////////////////////////////////////////////////////////////////////      
     function getFolderIndex(bytes32 protocol) view public returns (uint256) { // will get protocol node address
         return folderIndex[protocol];
     }
     function getFolderFromNodeId(bytes32 folderNodeId) view public returns (bytes32) {
         if(NodeIdToFolder[folderNodeId]==0)
            return root;
            
         return NodeIdToFolder[folderNodeId];
     }
     
     // ONLY OWNERS CAN ACCESS COMPLETE INFORMATION
     ///////////////////////////////////////////////////////////////////////////////////////////      
     function getAllFoldersCount() onlyOwner view public returns (uint256) { // get num of folder
         return folders.length;
     }
     function getAllFolders() onlyOwner view public returns (bytes32[] memory) { // get all folder
         return folders;
     }     
     function getFolderAt(uint256 idx) onlyOwner view public returns (bytes32) { // get folder by idx
         return folders[idx];
     }
     ///////////////////////////////////////////////////////////////////////////////////////////
     
     ///////////////////////////////////////////////////////////////////////////////////////////
     function getAllSenders() onlyOwner view public returns (bytes32[] memory) { // get all senders
         return senders;
     }
     function getAllSendersCount() onlyOwner view public returns (uint256) { // get num of senders
         return senders.length;
     }
     function getSenderAt(uint256 idx) onlyOwner view public returns (bytes32) { // get sender by idx
         return senders[idx];
     }
     ///////////////////////////////////////////////////////////////////////////////////////////
     
     ///////////////////////////////////////////////////////////////////////////////////////////
     function getSendersCount(bytes32 folder) onlyOwner view public returns (uint256) { // get num of senders by by protocol
         if(folderNodes[folder]==0) // folder does not exist
             return Nodes[root].senders.length;
             
         return Nodes[folderNodes[folder]].senders.length;
     }
     function getSender(bytes32 folder, uint256 idx) onlyOwner view public returns (bytes32) { // get sender by idx
         if(folderNodes[folder]==0) // folder does not exist
             return Nodes[root].senders[idx];
     
         return Nodes[folderNodes[folder]].senders[idx];
     }
     function getSenders(bytes32 folder) onlyOwner view public returns (bytes32[] memory) { // get all senders of protocol
         if(folderNodes[folder]==0) // folder does not exist
             return Nodes[root].senders;
     
         return Nodes[folderNodes[folder]].senders;
     }
     ///////////////////////////////////////////////////////////////////////////////////////////
 
     ///////////////////////////////////////////////////////////////////////////////////////////
     function getFeedsCount(bytes32 folder) onlyOwner view public returns (uint256) {
         if(folderNodes[folder]==0) // folder does not exist
             return Nodes[root].feeds.length;
         
         return Nodes[folderNodes[folder]].feeds.length;
     }
     function getFeedAt(bytes32 folder, uint256 idx) onlyOwner view public returns (bytes32) {
         if(folderNodes[folder]==0) // folder does not exist
             return Nodes[root].feeds[idx];
         
         return Nodes[folderNodes[folder]].feeds[idx];
     }
     function getFeeds(bytes32 folder) onlyOwner view public returns (bytes32[] memory) {
         if(folderNodes[folder]==0) // folder does not exist
             return Nodes[root].feeds;
         
         return Nodes[folderNodes[folder]].feeds;
     }
     ///////////////////////////////////////////////////////////////////////////////////////////
     function getFeedsOfSenderForFolder(bytes32 sender, bytes32 folder) onlyOwner view public returns (bytes32[] memory) {
         return senderFolderFeeds[sender][folder];
     }
     ///////////////////////////////////////////////////////////////////////////////////////////
 }
