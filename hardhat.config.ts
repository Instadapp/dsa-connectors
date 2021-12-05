import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@tenderly/hardhat-tenderly";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-web3";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "@typechain/hardhat";

import { resolve } from "path";
import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";
import { utils } from "ethers";
import Web3 from "web3";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const chainIds = {
  ganache: 1337,
  goerli: 5,
  hardhat: 31337,
  kovan: 42,
  mainnet: 1,
  rinkeby: 4,
  ropsten: 3,
  avalanche: 43114,
  polygon: 137,
};

const alchemyApiKey = process.env.ALCHEMY_API_KEY;
if (!alchemyApiKey) {
  throw new Error("Please set your ALCHEMY_API_KEY in a .env file");
}

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ETHERSCAN_API = process.env.ETHERSCAN_API_KEY;
const POLYGONSCAN_API = process.env.POLYGON_API_KEY;
const ARBISCAN_API = process.env.ARBISCAN_API_KEY;
const SNOWTRACE_API = process.env.SNOWTRACE_API_KEY;
const mnemonic = process.env.MNEMONIC;

function createTestnetConfig(
  network: keyof typeof chainIds
): NetworkUserConfig {
  const url: string =
    "https://eth-" + network + ".alchemyapi.io/v2/" + alchemyApiKey;
  return {
    accounts: {
      count: 10,
      initialIndex: 0,
      mnemonic,
      path: "m/44'/60'/0'/0",
    },
    chainId: chainIds[network],
    url,
  };
}

function getNetworkUrl(networkType: string) {
  //console.log(process.env);
  if (networkType === "avalanche")
    return "https://api.avax.network/ext/bc/C/rpc";
  else if (networkType === "polygon")
    return `https://polygon-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "arbitrum")
    return `https://arb-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else return `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKey}`;
}

function getScanApiKey(networkType: string) {
  if (networkType === "avalanche") return SNOWTRACE_API;
  else if (networkType === "polygon") return POLYGONSCAN_API;
  else if (networkType === "arbitrum") return ARBISCAN_API;
  else return ETHERSCAN_API;
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: true,
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
    hardhat: {
      accounts: {
        mnemonic,
      },
      chainId: chainIds.hardhat,
      forking: {
        url: String(getNetworkUrl(String(process.env.networkType))),
      },
    },
    goerli: createTestnetConfig("goerli"),
    kovan: createTestnetConfig("kovan"),
    rinkeby: createTestnetConfig("rinkeby"),
    ropsten: createTestnetConfig("ropsten"),
    mainnet: {
      url: getNetworkUrl("mainnet"),
    },
    polygon: {
      url: getNetworkUrl("polygon"),
    },
    avalanche: {
      url: getNetworkUrl("avalanche"),
    },
    arbitrum: {
      url: getNetworkUrl("arbiturm"),
    },
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  etherscan: {
    apiKey: getScanApiKey(getNetworkUrl(String(process.env.networkType))),
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  mocha: {
    timeout: 10000 * 1000, // 10,000 seconds
  },
  // tenderly: {
  //   project: process.env.TENDERLY_PROJECT,
  //   username: process.env.TENDERLY_USERNAME,
  // },
};

export default config;
