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
import { network } from "hardhat";
import bigNumber from "bignumber.js";
import "./scripts/tests/run_test_through_cmd";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const chainIds = {
  ganache: 1337,
  hardhat: 31337,
  mainnet: 1,
  avalanche: 43114,
  polygon: 137,
  arbitrum: 42161,
  optimism: 10,
  fantom: 250
};

const alchemyApiKey = process.env.ALCHEMY_API_KEY;
if (!alchemyApiKey) {
  throw new Error("Please set your ALCHEMY_API_KEY in a .env file");
}

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const mnemonic = process.env.MNEMONIC ?? "test test test test test test test test test test test junk";

const networkGasPriceConfig: Record<string, number> = {
  mainnet: 100,
  polygon: 50,
  avalanche: 40,
  arbitrum: 1,
  optimism: 0.001,
  fantom: 210
};

function createConfig(network: string) {
  return {
    url: getNetworkUrl(network),
    accounts: !!PRIVATE_KEY ? [`0x${PRIVATE_KEY}`] : { mnemonic },
    gasPrice: new bigNumber(networkGasPriceConfig[network]).multipliedBy(1e9).toNumber() // Update the mapping above
  };
}

function getNetworkUrl(networkType: string) {
  if (networkType === "avalanche") return "https://api.avax.network/ext/bc/C/rpc";
  else if (networkType === "polygon") return `https://polygon-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "arbitrum") return `https://arb-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "optimism") return `https://opt-mainnet.g.alchemy.com/v2/${alchemyApiKey}`;
  else if (networkType === "fantom") return `https://rpc.ftm.tools/`;
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
            runs: 200
          }
        }
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
    hardhat: {
      accounts: {
        mnemonic
      },
      chainId: chainIds.hardhat,
      forking: {
        url: String(getNetworkUrl(String(process.env.networkType)))
      }
    },
    mainnet: createConfig("mainnet"),
    polygon: createConfig("polygon"),
    avalanche: createConfig("avalanche"),
    arbitrum: createConfig("arbitrum"),
    optimism: createConfig("optimism"),
    fantom: createConfig("fantom")
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test"
  },
  etherscan: {
    apiKey: {
      mainnet: String(process.env.MAIN_ETHSCAN_KEY),
      optimisticEthereum: String(process.env.OPT_ETHSCAN_KEY),
      polygon: String(process.env.POLY_ETHSCAN_KEY),
      arbitrumOne: String(process.env.ARB_ETHSCAN_KEY),
      avalanche: String(process.env.AVAX_ETHSCAN_KEY),
      opera: String(process.env.FTM_ETHSCAN_KEY)
    }
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5"
  },
  mocha: {
    timeout: 10000 * 1000 // 10,000 seconds
  }
  // tenderly: {
  //   project: process.env.TENDERLY_PROJECT,
  //   username: process.env.TENDERLY_USERNAME,
  // },
};

export default config;
