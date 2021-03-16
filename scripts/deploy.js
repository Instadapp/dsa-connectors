const hre = require("hardhat");
const { ethers } = hre;

const deployConnector = require("./deployConnector");

async function main() {
    const accounts = await hre.ethers.getSigners()
    const wallet = accounts[0]
    
    const connectMapping = {
        '1INCH-A': 'ConnectV2OneInch',
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
    
    const connectorsAbi = [
        "function addConnectors(string[] _connectorNames, address[] _connectors)"
    ]
    
    // Replace the address with correct v2 connectors registry address
    const connectorsContract = new ethers.Contract("0x84b457c6D31025d56449D5A01F0c34bF78636f67", connectorsAbi, wallet)
    
    await connectorsContract.addConnectors(Object.keys(addressMapping), Object.values(addressMapping))
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
