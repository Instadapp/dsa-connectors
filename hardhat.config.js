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
      }
    ]
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
