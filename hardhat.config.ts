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
import "./scripts/tests/run-tests"


dotenvConfig({ path: resolve(__dirname, "./.env") });

const chainIds = {
  ganache: 1337,
  hardhat: 31337,
  mainnet: 1,
  avalanche: 43114,
  polygon: 137,
  arbitrum: 42161,
  optimism: 10
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
const mnemonic =
  process.env.MNEMONIC ??
  "test test test test test test test test test test test junk";

const networkGasPriceConfig: Record<string, Number> = {
  "mainnet": 160,
  "polygon": 50,
  "avalanche": 25,
  "arbitrum":1,
}

function createConfig(network: string) {
  return {
    url: getNetworkUrl(network),
    accounts: !!PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : { mnemonic },
    gasPrice: Number(networkGasPriceConfig[network])*1e9, // 0.0001 GWEI
  };
}

function getNetworkUrl(networkType: string) {
  if (networkType === "avalanche")
    return "https://api.avax.network/ext/bc/C/rpc";
  else if (networkType === "polygon")
    return `https://polygon-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "arbitrum")
    return `https://arb-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "optimism")
    return `https://opt-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else return `https://eth-mainnet.alchemyapi.io/v2/${alchemyApiKey}`;
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
    mainnet: createConfig("mainnet"),
    polygon: createConfig("polygon"),
    avalanche: createConfig("avalanche"),
    arbitrum: createConfig("arbitrum"),
    optimism: createConfig("optimism"),
  }, 
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  etherscan: { 
     apiKey: {
       mainnet: String(ETHERSCAN_API),
       polygon: String(POLYGONSCAN_API),
       arbitrumOne: String(ARBISCAN_API),
       avalanche: String(SNOWTRACE_API),
     }
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
