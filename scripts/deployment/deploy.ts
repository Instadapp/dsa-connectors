import { ethers } from "hardhat";
import { deployConnector } from "./deployConnector";

async function main() {
  const accounts = await ethers.getSigners();

  const connectMapping: Record<string, string> = {
    "UniswapV3-v1" : "ConnectV2UniswapV3Polygon", 
    "Uniswap-V3-Staker-v1.1" : "ConnectV2UniswapV3StakerPolygon"
  };

  const addressMapping: Record<string, string> = {};

  for (const key in connectMapping) {
    addressMapping[key] = await deployConnector(connectMapping[key]);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
