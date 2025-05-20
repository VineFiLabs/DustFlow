require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: { 
    pharos_dev: {
      url: process.env.Pharos_Devnet_Rpc,
      accounts: [process.env.PRIVATE_KEY1]
    },
    pharos_testnet: {
      url: process.env.Pharos_Testnet_Rpc,
      accounts: [process.env.PRIVATE_KEY1]
    },
    arb_sepolia: {
      url: process.env.Arbitrum_Sepolia_Rpc,
      accounts: [process.env.PRIVATE_KEY1]
    },
    base_sepolia: {
      url: process.env.Base_Sepolia_Rpc,
      accounts: [process.env.PRIVATE_KEY1]
    },
    monad_testnet: {
      url: process.env.Monad_Testnet_RPC,
      accounts: [process.env.PRIVATE_KEY1]
    },
    sonic_testnet: {
      url: process.env.Sonic_Testnet_RPC,
      accounts: [process.env.PRIVATE_KEY1]
    },
    bnb_testnet: {
      url: process.env.Bnb_Testnet_RPC,
      accounts: [process.env.PRIVATE_KEY1]
    }
  },
  solidity: {
    compilers:[
      {version: "0.8.23"},
    ],
    settings: {
      optimizer: {
        enabled: false,
        runs: 200
      }
    }
  },
  gasReporter: {
    enabled: false,  
    currency: 'ETH',  
    // coinmarketcap: 'YOUR_API_KEY',
    outputFile: 'gas-report.txt', 
    noColors: true 
  },
  sourcify: {
    enabled: true
  },
  etherscan: {
    // apiKey: process.env.
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 4000
  }
  };
