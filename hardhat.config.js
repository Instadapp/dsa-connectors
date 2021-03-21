require("@nomiclabs/hardhat-ethers");
require("@tenderly/hardhat-tenderly");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

const { utils } = require("ethers");

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ALCHEMY_ID = process.env.ALCHEMY_ID;

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.7.6"
      },
      {
        version: "0.6.0"
      },
      {
        version: "0.6.2"
      },
      {
        version: "0.6.5"
      }
    ]
  },
  networks: {
    mainnet: {
      url: process.env.ETH_NODE_URL,
      chainId: 1,
      timeout: 500000,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    kovan: {
      url: `https://eth-kovan.alchemyapi.io/v2/${ALCHEMY_ID}`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    mainnet: {
      url: `https://eth.alchemyapi.io/v2/${ALCHEMY_ID}`,
      accounts: [`0x${PRIVATE_KEY}`],
      timeout: 150000,
      gasPrice: parseInt(utils.parseUnits("161", "gwei"))
    },
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
        blockNumber: 12070498,
      },
      blockGasLimit: 12000000,
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  tenderly: {
    project: process.env.TENDERLY_PROJECT,
    username: process.env.TENDERLY_USERNAME,
  }
};
