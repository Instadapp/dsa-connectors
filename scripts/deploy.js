const hre = require("hardhat");
const { ethers } = hre;

const deployConnector = require("./deployConnector");

async function main() {
    const accounts = await hre.ethers.getSigners()
    const wallet = accounts[0]
    
    const connectMapping = {
        '1INCH-A': 'ConnectV2OneInch',
        '1INCH-B': 'ConnectV2OneProto',
        'AAVE-V1-A': 'ConnectV2AaveV1',
        'AAVE-V2-A': 'ConnectV2AaveV2',
        'AUTHORITY-A': 'ConnectV2Auth',
        'BASIC-A': 'ConnectV2Basic',
        'COMP-A': 'ConnectV2COMP',
        'COMPOUND-A': 'ConnectV2Compound',
        'DYDX-A': 'ConnectV2Dydx',
        'FEE-A': 'ConnectV2Fee',
        'GELATO-A': 'ConnectV2Gelato',
        'MAKERDAO-A': 'ConnectV2Maker',
        'UNISWAP-A': 'ConnectV2UniswapV2'
    }
    
    const addressMapping = {}
    
    for (const key in connectMapping) {
        addressMapping[key] = await deployConnector(connectMapping[key])
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
