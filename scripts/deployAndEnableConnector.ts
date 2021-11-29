import { addresses } from "./constant/addresses";
import { abis } from "./constant/abis";

// const { deployContract } = waffle;
import { ethers } from "hardhat";
import { promises as fs } from "fs";
import { deployContract } from "ethereum-waffle";

export async function deployAndEnableConnector({
  connectorName,
  contractArtifact,
  signer,
  connectors,
}) {
  const connectorInstanace = await deployContract(signer, contractArtifact, []);

  await connectors
    .connect(signer)
    .addConnectors([connectorName], [connectorInstanace.address]);

  addresses.connectors[connectorName] = connectorInstanace.address;
  abis.connectors[connectorName] = contractArtifact.abi;

  return connectorInstanace;
}
