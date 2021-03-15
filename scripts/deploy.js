const hre = require("hardhat");
const { ethers } = hre;

const deployConnector = require("./deployConnector");

async function main() {
    const accounts = await hre.ethers.getSigners()
    const wallet = accounts[0]
    
    const connectMapping = {
        '1inch-A': 'ConnectV2OneInch',
        'aave-v1-A': 'ConnectV2AaveV1',
        'aave-v2-A': 'ConnectV2AaveV2',
        'authority-A': 'ConnectV2Auth',
        'basic-A': 'ConnectV2Basic',
        'comp-A': 'ConnectV2COMP',
        'compound-A': 'ConnectV2Compound',
        'dydx-A': 'ConnectV2Dydx',
        'fee-A': 'ConnectV2Fee',
        'gelato-A': 'ConnectV2Gelato',
        'makerdao-A': 'ConnectV2Maker',
        'uniswap-A': 'ConnectV2UniswapV2'
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
