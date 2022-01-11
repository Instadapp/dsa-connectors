import hre, { ethers } from "hardhat";
import { execScript } from "../tests/command";

export const deployConnector = async (connectorName?: string) => {
  connectorName = String(process.env.connectorName) ?? connectorName;
  const Connector = await ethers.getContractFactory(connectorName);
  const connector = await Connector.deploy();
  await connector.deployed();

  console.log(`${connectorName} Deployed: ${connector.address}`);

  const chain = String(hre.network.name);
  if (chain !== "hardhat") {
    try {
      await execScript({
        cmd: "npx",
        args: [
          "hardhat",
          "verify",
          "--network",
          `${chain}`,
          `${connector.address}`,
        ],
        env: {
          networkType: chain,
        },
      });
    } catch (error) {
      console.log(`Failed to verify: ${connectorName}@${connector.address}`);
      console.log(error);
      console.log();
    }
  }

  return connector.address;
};
