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
    const allPaths = await hre.artifacts.getArtifactPaths();

    let connectorPath;
    for (const path of allPaths)
      if (path.split("/").includes(connectorName + ".json"))
        connectorPath = path.slice(path.indexOf("contracts"), path.indexOf(connectorName) - 1) + `:${connectorName}`;

    try {
      await execScript({
        cmd: "npx",
        args: ["hardhat", "verify", "--network", `${chain}`, `${connector.address}`, "--contract", `${connectorPath}`],
        env: {
          networkType: chain
        }
      });
    } catch (error) {
      console.log(`Failed to verify: ${connectorName}@${connector.address}`);
      console.log(error);
      console.log();
    }
  }

  return connector.address;
};
