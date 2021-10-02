const hre = require("hardhat");
const { ethers } = hre;

module.exports = async (connectorName) => {
    // const Connector = await ethers.getContractFactory(connectorName);
    // const connector = await Connector.deploy();
    // await connector.deployed();

    // console.log(`${connectorName} Deployed: ${connector.address}`);

    try {
        await hre.run("verify:verify", {
            address: "0x9926955e0dd681dc303370c52f4ad0a4dd061687",
            constructorArguments: [],
            contract: "contracts/fantom/connectors/basic/main.sol:ConnectV2BasicFantom"
          }
        )
    } catch (error) {
        // console.log(`Failed to verify: ${connectorName}@${connector.address}`)
        console.log(error)
        console.log()
    }

    return connector.address
}