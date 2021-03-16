require("@nomiclabs/hardhat-ethers");
require("@tenderly/hardhat-tenderly");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

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
    tenderlyMainnet: {
      url: 'https://mainnet.tenderly.co',
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 1,
      gasPrice: 25120000000,
      timeout: 500000
    },
    tenderlyKovan: {
      url: 'https://kovan.tenderly.co',
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 42,
      gasPrice: 40000000000,
      timeout: 50000
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  },
  tenderly: {
    project: process.env.TENDERLY_PROJECT,
    username: process.env.TENDERLY_USERNAME,
  }
};
