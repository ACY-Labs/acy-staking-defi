require('dotenv').config();


const mnemonic = process.env.MNEMONIC;
const HDWalletProvider = require("@truffle/hdwallet-provider");
console.log(mnemonic)


module.exports = {

  networks: {

    development: {
     host: "127.0.0.1",     
     port: 1337,            
     network_id: "*", 
    },

    mumbai: {
      provider: new HDWalletProvider(mnemonic, process.env.POLYGON_MUMBAI_RPC),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    }

  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.0",    // Fetch exact version from solc-bin (default: truffle's version)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
       optimizer: {
         enabled: true,
         runs: 200
       },
      }
    }
  },

};
