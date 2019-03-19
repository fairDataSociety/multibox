/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */

 pragma solidity ^0.5.0;
 
 contract Multibox {
    mapping(bytes32 => bytes32) protocolNodes; // map of protocols to NodeId
    
    mapping(bytes32 => uint256) protocolIndex; // map of protocols to index
    bytes32[] protocols; // all protocols roots

    mapping(bytes32 => uint256) senderMap; // map of senders
    bytes32[] senders; // all senders
    
    mapping(bytes32 => mapping(bytes32 => bytes32[])) internal senderProtocolFeeds; // feeds by sender by protocol
    
    struct Node
    {
        bool      isNode;
        bytes32   parent;
        uint256   parentIndex;
        // consider putting protocol info in a node 

        mapping(bytes32 => bytes32) feedsMap;
        bytes32[] senders;
        bytes32[] feeds;

        //mapping(bytes32 => bytes32) childrenMap; // protocol to childId
        bytes32[] children; 
    }
    
    mapping(bytes32 => Node) internal Nodes; // NodeId to node
    mapping(bytes32 => bytes32) internal NodeIdToProtocol; // nodeIds to protocol 
    
    function isNode(bytes32 nodeId) public view returns(bool isIndeed)  {
        return Nodes[nodeId].isNode;
    }
    function getNodeCount(bytes32 nodeId) public view returns(uint childCount) {
        return Nodes[nodeId].children.length;
    }
    function getNodeAtIndex(bytes32 nodeId, uint index) public view returns(bytes32 childId) {
        return Nodes[nodeId].children[index];
    }
    function newProtocol(bytes32 parent) internal returns(bytes32 newId) {
        if(!isNode(parent) && parent > 0) revert(); // zero is a new root node
        newId = keccak256(abi.encodePacked(parent, msg.sender, block.number));
        Node memory node;
        node.parent = parent;
        node.isNode = true;
        // more node atributes here
        if(parent>0) {
            node.parentIndex = registerChild(parent,newId);
        }
        Nodes[newId] = node;
        return newId;
    }
    function registerChild(bytes32 parentId, bytes32 childId) private returns(uint index) {
        return Nodes[parentId].children.push(childId) - 1;
    }
    
    address internal owner;
    uint256 version;
    bytes32 public root; // root of protocol trees

    modifier only_owner() {
         require(owner == msg.sender);
         _;
    }

     /**
      * Constructor.
      */
     constructor() public {
         owner = msg.sender;
         root = newProtocol(0); // the root of all 
         version = 1;
         
     }
     function getVersion() public view returns (uint256) {
         return version;
     }

     // so the problem is that subProtocol is added to protocolNodes mapping
     // but this means that subProtocol can be only one and must be unique 
     // which in turn means that we can't have same subProtocol in different parent protocols
     // add subProtocol to parentProtocol (protocolNodeId)
     function addSubProtocol(bytes32 parentProtocol, bytes32 subProtocol) public returns (bool) {
        if(protocolNodes[parentProtocol] == 0) // if no such protocol then add protocol (only unique protocols are added)
            return false;
        
        // there can be only ONE subprotocol, calculate subProtocol hash with something like hash(parentName.subProtocolName)
        if(protocolNodes[subProtocol] != 0) // if subProtocol exists as protocol, then fail
            return false;
         
        bytes32 parentProtocolNodeId =  getProtocolNodeAddress(parentProtocol); // we add by nodeId not by protocolId 
        
        protocolIndex[subProtocol] = protocols.push(subProtocol)-1;
        protocolNodes[subProtocol] = newProtocol(parentProtocolNodeId); // add child to parent
        
        NodeIdToProtocol[protocolNodes[subProtocol]] = subProtocol; // we need mapping to protocol from nodeId
     }
     
     function newRequest(bytes32 protocol, bytes32 sender, bytes32 feed) public returns (bool) {
         //Node memory node = Nodes[root]; 
         if(protocolNodes[protocol]==0) {// protocol does not exist in mapping to all protocols
             addSubProtocol(root, protocol);
         }
         if(senderMap[sender] == 0) { // if no such sender exits (only unique senders)
            senderMap[sender] = senders.push(sender)-1;
         }
         
         Node storage node = Nodes[protocolNodes[protocol]];
         if(node.feedsMap[sender] == 0x0)
         {
            node.senders.push(sender);
            node.feeds.push(feed); 
            node.feedsMap[sender] = feed;
         }
         
         senderProtocolFeeds[sender][protocol].push(feed);

         return true;
     }

     function getRequests(bytes32 protocol) view public returns (bytes32[] memory) {
         if(protocolNodes[protocol]==0) // protocol does not exist
             return Nodes[root].senders;
             
         return Nodes[protocolNodes[protocol]].senders;
     }
     
     function getRequest(bytes32 protocol, bytes32 sender) public view returns (bytes32) {
         if(protocolNodes[protocol]==0) // protocol does not exist         {
             return Nodes[root].feedsMap[sender];
             
         return Nodes[protocolNodes[protocol]].feedsMap[sender];
     }
     
     ///////////////////////////////////////////////////////////////////////////////////////////      
     function getProtocolNodeAddress(bytes32 protocol) view public returns (bytes32) { // will get protocol node address
         if(protocolNodes[protocol]==0) // protocol does not exist
             return root;     
             
         return protocolNodes[protocol];
     }
     function getProtocolChildrenNodeIDs(bytes32 protocolNodeId) view public returns (bytes32[] memory) { // will get protocol node address
         return Nodes[protocolNodeId].children;
     }
     ///////////////////////////////////////////////////////////////////////////////////////////      
     function getProtocolIndex(bytes32 protocol) view public returns (uint256) { // will get protocol node address
         return protocolIndex[protocol];
     }
     function getProtocolFromNodeId(bytes32 protocolNodeId) view public returns (bytes32)
     {
         if(NodeIdToProtocol[protocolNodeId]==0)
            return root;
            
         return NodeIdToProtocol[protocolNodeId];
     }
     ///////////////////////////////////////////////////////////////////////////////////////////      
     function getAllProtocolsCount() view public returns (uint256) { // get num of protocols
         return protocols.length;
     }
     function getAllProtocols() view public returns (bytes32[] memory) { // get all protocols
         return protocols;
     }     
     function getProtocol(uint256 idx) view public returns (bytes32) { // get protocol by idx
         return protocols[idx];
     }
     ///////////////////////////////////////////////////////////////////////////////////////////
     function getAllSenders() view public returns (bytes32[] memory) { // get all senders
         return senders;
     }
     function getAllSendersCount() view public returns (uint256) { // get num of protocols
         return senders.length;
     }
     function getAllSender(uint256 idx) view public returns (bytes32) { // get protocol by idx
         return senders[idx];
     }
     
     ///////////////////////////////////////////////////////////////////////////////////////////
     function getSendersCount(bytes32 protocol) view public returns (uint256) { // get num of senders by by protocol
         if(protocolNodes[protocol]==0) // protocol does not exist
             return Nodes[root].senders.length;
             
         return Nodes[protocolNodes[protocol]].senders.length;
     }
     function getSender(bytes32 protocol, uint256 idx) view public returns (bytes32) { // get sender by idx
         if(protocolNodes[protocol]==0) // protocol does not exist
             return Nodes[root].senders[idx];
     
         return Nodes[protocolNodes[protocol]].senders[idx];
     }
     function getSenders(bytes32 protocol) view public returns (bytes32[] memory) { // get all senders of protocol
         if(protocolNodes[protocol]==0) // protocol does not exist
             return Nodes[root].senders;
     
         return Nodes[protocolNodes[protocol]].senders;
     }
     ///////////////////////////////////////////////////////////////////////////////////////////
 
     ///////////////////////////////////////////////////////////////////////////////////////////
     function getFeedsCount(bytes32 protocol) view public returns (uint256) {
         if(protocolNodes[protocol]==0) // protocol does not exist
             return Nodes[root].feeds.length;
         
         return Nodes[protocolNodes[protocol]].feeds.length;
     }
     function getFeed(bytes32 protocol, uint256 idx) view public returns (bytes32) {
         if(protocolNodes[protocol]==0) // protocol does not exist
             return Nodes[root].feeds[idx];
         
         return Nodes[protocolNodes[protocol]].feeds[idx];
     }
     function getFeeds(bytes32 protocol) view public returns (bytes32[] memory) {
         if(protocolNodes[protocol]==0) // protocol does not exist
             return Nodes[root].feeds;
         
         return Nodes[protocolNodes[protocol]].feeds;
     }
     ///////////////////////////////////////////////////////////////////////////////////////////
     function getFeedsOfSenderForProtocol(bytes32 sender, bytes32 protocol) view public returns (bytes32[] memory) {
         return senderProtocolFeeds[sender][protocol];
     }
     ///////////////////////////////////////////////////////////////////////////////////////////
 }
