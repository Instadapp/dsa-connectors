const hre = require("hardhat");
const { ethers } = hre;

const deployConnector = require("./deployConnector");

async function main() {
    const connectors = [
      'ConnectV2OneInch',
      'ConnectV2AaveV1',
      'ConnectV2AaveV2',
      'ConnectV2Auth',
      'ConnectV2Basic',
      'ConnectV2COMP',
      'ConnectV2Compound',
      'ConnectV2Dydx',
      'ConnectV2Fee',
      'ConnectV2Gelato',
      'ConnectV2Maker',
      'ConnectV2UniswapV2'
    ]

    for (const connector of connectors) {
      await deployConnector(connector)
    }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });