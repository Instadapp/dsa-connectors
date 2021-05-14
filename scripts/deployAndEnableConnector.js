const abis = require("./constant/abis");
const addresses = require("./constant/addresses");

const hre = require("hardhat");
const { ethers, waffle } = hre;
const { deployContract } = waffle;
const fs = require("fs")


module.exports = async function ({connectorName, contractArtifact, signer, connectors}) {
    const connectorInstanace = await deployContract(signer, contractArtifact, []);
    
    await connectors.connect(signer).addConnectors([connectorName], [connectorInstanace.address])

    addresses.connectors[connectorName] = connectorInstanace.address
    abis.connectors[connectorName] = contractArtifact.abi;

    return connectorInstanace;
};
