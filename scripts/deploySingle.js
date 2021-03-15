const hre = require("hardhat");
const { ethers } = hre;

const deployConnector = require("./deployConnector");

async function main() {
    const address = await deployConnector("ConnectOne") // Example

    const connectorsAbi = [
        "function addConnectors(string[] _connectorNames, address[] _connectors)"
    ]

    const connectorsContract = new ethers.Contract("0x84b457c6D31025d56449D5A01F0c34bF78636f67", connectorsAbi, ethers.provider);

    await connectorsContract.addConnectors(['1inch'], [address])
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });