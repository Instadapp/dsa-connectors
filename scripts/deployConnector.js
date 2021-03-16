const hre = require("hardhat");
const { ethers } = hre;

module.exports = async (connectorName) => {
    const Connector = await ethers.getContractFactory(connectorName);
    const connector = await Connector.deploy();
    await connector.deployed();

    console.log(`${connectorName} Deployed: ${connector.address}`);

    try {
        await hre.run("verify:verify", {
            address: connector.address,
            constructorArguments: []
          }
        )
    } catch (error) {
        console.log(`Failed to verify: ${connectorName}@${connector.address}`)
        console.log(error)
        console.log()
    }

    return connector.address
}