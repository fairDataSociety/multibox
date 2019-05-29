# Multibox
PLEASE NOTE THIS IS WORK IN PROGRESS AND NOT FINAL!

Good things come in Multiboxes 🎁

# What is Multibox?
Multibox is Fairdrop’s upgrade and provides a scalable way to share encrypted data in a peer-to-peer manner. It gives users the means to write data into the individual’s accounts, along with the ability to categorise that data in a systematic way. At its core multibox is a set of smart contracts that enable some interesting additional functionalities. Think of it as multiple storage devices with custom folders. 

# Why Multibox?
We are looking to bring teams on board that will have an impact to change paradigm, work on zero data apps, contribute to a larger coherent development of how data is given back to user.

# How Multibox works
Multibox is meant to be used in conjunction with the fds.js library and Swarm’s decentralized storage. 
Keep in mind that some of the functionality was taken out due to optimization, to reduce gas consumption costs or simply because off chain manipulation is required due to technological limitations.

## Multibox is composed of three contracts:
- Main contract, ie. Multibox, 
- key-value tree contract (tree), 
- data access request contract

### Multibox
- Create KVTs
- Add KVTs from other multiboxes 
- Manage data access requests 

Main contract acts as an entry point to individual’s trees. It enables the creation of a new trees and can accept trees shared by other multibox accounts. Contract can receive funds, but only owner can withdraw. Other multibox users can request access to a contained node of specific tree by deploying new data access request contract

### KVT tree 
- Nodes 
- Access rights per node
- node contains Set of Key Value pairs 

A key-value tree contract contains nodes that hold key-value pairs and children nodes. Applications must assure node identifiers are unique or else addition of new node will fail. Key value pairs are bytes32. What pairs represent is developers concern, in fds.js they represent (but are not limited to) sender information as a key and swarm feed location as a value.
Controlling access rights can be done only by owner of tree contract on each node level. Access rights are defined for each node separately and do not propagate down the tree.

But what is someone tracks all transactions on blockchain? He can know what is written in each node? Well data at locations is still encrypted, so going through this effort is useless. 

### Data Access Request
- Similar to an escrow account
- Other multiboxes and accounts can ask for access 
- Supports deposit/withdrawal of funds
- Approval is done by proof that access key was shared  
- custom value propositions. 

Data access request contract is similar to an escrow account and supports the deposit and withdrawal of funds from it. Other multibox owners can send an access rights request to a multibox for specific tree and node. 

#### Requesting data access 
If owner grants access rights to it, deposit is transfered. This procedure is a bit more complicated, as its not only the rights to node must be given, also a private key must be shared.
This is usually shared to requestors KVT0 '/shared/access/rights/kvtAddress'.   





# Installation
Install Truffle
`npm install -g truffle`

Install Ganache-Cli
`npm install -g ganache-cli`

Start Ganache-Cli
`ganache-cli`

Run Migrations
`truffle migrate`

## Development
Run Tests
`truffle test`

Use Console
`truffle console`

Refresh Contracts
`truffle migrate`

## Debugging

Debug Using Chrome
Find out where your node binary is....
`which node`

`/Users/significance/.nvm/versions/node/v8.11.2/bin/node`

work out where the js file that runs the node cli is
`/Users/significance/.nvm/versions/node/v8.11.2/lib/node_modules/truffle/build/cli.bundled.js`

run this with the `--inspect-bk` flag, `test` keyword and path to your test.
`node --inspect-bk /Users/significance/.nvm/versions/node/v8.11.2/lib/node_modules/truffle/build/cli.bundled.js test test/multibox.js`

navigate to `chrome://inspect`
click `Open dedicated DevTools for Node`
click `Sources`
click `Add Folder to Workspace` and select your tests folder.

now running
`node --inspect-bk /Users/significance/.nvm/versions/node/v8.11.2/lib/node_modules/truffle/build/cli.bundled.js test test/multibox.js`

should show in the devtools console.

https://ethereum.stackexchange.com/a/43633/3883