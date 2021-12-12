import { ethers } from "hardhat";

export const deployConnector = async (connectorName: string) => {
  const Connector = await ethers.getContractFactory(connectorName);
  const connector = await Connector.deploy();
  await connector.deployed();

  console.log(`${connectorName} Deployed: ${connector.address}`);
  return connector.address;
};
