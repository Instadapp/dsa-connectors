import hre, { ethers } from "hardhat";

export const deployConnector = async (connectorName?: string) => {
  connectorName = String(process.env.connectorName) ?? connectorName;
  const Connector = await ethers.getContractFactory(connectorName);
  const connector = await Connector.deploy();
  await connector.deployed();

  console.log(`${connectorName} Deployed: ${connector.address}`);

  try {
    await hre.run("verify:verify", {
      address: connector.address,
      constructorArguments: [],
    });
  } catch (error) {
    console.log(`Failed to verify: ${connectorName}@${connector.address}`);
    console.log(error);
    console.log();
  }
  return connector.address;
};
