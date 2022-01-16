import { ethers } from "hardhat";
import { deployConnector } from "./deployConnector";

async function main() {
  const accounts = await ethers.getSigners();

  const connectMapping: Record<string, string> = {
    "1INCH-A": "ConnectV2OneInch",
    "1INCH-B": "ConnectV2OneProto",
    "AAVE-V1-A": "ConnectV2AaveV1",
    "AAVE-V2-A": "ConnectV2AaveV2",
    "AUTHORITY-A": "ConnectV2Auth",
    "BASIC-A": "ConnectV2Basic",
    "COMP-A": "ConnectV2COMP",
    "COMPOUND-A": "ConnectV2Compound",
    "DYDX-A": "ConnectV2Dydx",
    "FEE-A": "ConnectV2Fee",
    "GELATO-A": "ConnectV2Gelato",
    "MAKERDAO-A": "ConnectV2Maker",
    "UNISWAP-A": "ConnectV2UniswapV2",
    "QUICKSWAP-A": "ConnectV2QuickswapPolygon",
    "UniswapV3-v1" : "ConnectV2UniswapV3Polygon", 
    "Uniswap-V3-Staker-v1.1" : "ConnectV2UniswapV3StakerPolygon",
    "Paraswap-v5" : "ConnectV2ParaswapV5Polygon",
    "1INCH-V4" : "ConnectV2OneInchV4Polygon",
    "ZEROEX-A": "ConnectV2ZeroExAvalanche",
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
