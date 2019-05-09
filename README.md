# Multibox

Good things come in Multiboxes 🎁

## Installation

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