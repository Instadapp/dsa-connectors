require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@tenderly/hardhat-tenderly");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-web3");
require("hardhat-deploy");
require("hardhat-deploy-ethers");
require("dotenv").config();

const { utils } = require("ethers");

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ALCHEMY_ID = process.env.ALCHEMY_ID;

if (!process.env.ALCHEMY_ID) {
  throw new Error("ENV Variable ALCHEMY_ID not set!");
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: false,
            runs: 200,
          },
        },
      },
      {
        version: "0.6.0",
      },
      {
        version: "0.6.2",
      },
      {
        version: "0.6.5",
      },
    ],
  },
  networks: {
    // defaultNetwork: "hardhat",
    kovan: {
      url: `https://eth-kovan.alchemyapi.io/v2/${ALCHEMY_ID}`,
      accounts: [`0x${PRIVATE_KEY}`],
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
      accounts: [`0x${PRIVATE_KEY}`],
      timeout: 150000,
      gasPrice: parseInt(utils.parseUnits("30", "gwei")),
    },
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
        blockNumber: 13005785,
      },
      blockGasLimit: 12000000,
      gasPrice: parseInt(utils.parseUnits("300", "gwei"))
    },
    matic: {
      url: "https://rpc-mainnet.maticvigil.com/",
      accounts: [`0x${PRIVATE_KEY}`],
      timeout: 150000,
      gasPrice: parseInt(utils.parseUnits("1", "gwei")),
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  tenderly: {
    project: process.env.TENDERLY_PROJECT,
    username: process.env.TENDERLY_USERNAME,
  },
  mocha: {
    timeout: 100 * 1000,
  },
};
