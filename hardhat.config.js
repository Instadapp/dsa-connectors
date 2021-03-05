require("@tenderly/hardhat-tenderly");
require('dotenv').config();

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
    },
    tenderlyMainnet: {
      url: 'https://mainnet.tenderly.co',
      accounts: [process.env.PRIVATE_KEY],
      chainId: 1,
      gasPrice: 25120000000,
      timeout: 500000
    },
    tenderlyKovan: {
      url: 'https://kovan.tenderly.co',
      accounts: [process.env.PRIVATE_KEY],
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
