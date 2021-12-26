import { ethers } from "hardhat";

export const deployConnector = async (connectorName?: string) => {
  connectorName = String(process.env.connectorName) ?? connectorName;
  const Connector = await ethers.getContractFactory(connectorName);
  const connector = await Connector.deploy();
  await connector.deployed();

  console.log(`${connectorName} Deployed: ${connector.address}`);
  return connector.address;
};
