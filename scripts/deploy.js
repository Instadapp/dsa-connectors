const hre = require("hardhat");
const { ethers } = hre;

const deployConnector = require("./deployConnector");

async function main() {

    const accounts = await hre.ethers.getSigners()
    const wallet = accounts[0]

    const connectMapping = {
        '1inch': 'ConnectV2OneInch',
        'aaveV1': 'ConnectV2AaveV1',
        // 'aaveV2': 'ConnectV2AaveV2',
        // 'auth': 'ConnectV2Auth',
        // 'basic': 'ConnectV2Basic',
        // 'comp': 'ConnectV2COMP',
        // 'compound': 'ConnectV2Compound',
        // 'dydx': 'ConnectV2Dydx',
        // 'fee': 'ConnectV2Fee',
        // 'gelato': 'ConnectV2Gelato',
        // 'maker': 'ConnectV2Maker',
        // 'uniswap': 'ConnectV2UniswapV2'
    }

    const addressMapping = {}

    for (const key in connectMapping) {
        addressMapping[key] = await deployConnector(connectMapping[key])
    }

    // const connectorsAbi = [
    //     "function addConnectors(string[] _connectorNames, address[] _connectors)"
    // ]

    // // Replace the address with correct v2 connectors registry address
    // const connectorsContract = new ethers.Contract("0x84b457c6D31025d56449D5A01F0c34bF78636f67", connectorsAbi, wallet)

    // await connectorsContract.addConnectors(Object.keys(addressMapping), Object.values(addressMapping))
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });