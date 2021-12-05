import { addressesPolygon } from "./polygon/addressesPolygon";
import { addresses } from "./mainnet/addresses";
import { abis } from "../constant/abis";

// const { deployContract } = waffle;
// import { ethers } from "hardhat";
// import { promises as fs } from "fs";
// import { deployContract } from "ethereum-waffle";

function getAddress(network: string | undefined) {
  if (network === "polygon") return addressesPolygon;
  // else if (network === "arbitrum") return addressesPolygon;
  // else if (network === "avalanche") return addressesPolygon;
  else return addresses;
}

export async function deployAndEnableConnector({
  connectorName,
  contractArtifact,
  signer,
  connectors,
}) {
  const deployer = new contractArtifact(signer);
  const connectorInstanace = await deployer.deploy();

  await connectors
    .connect(signer)
    .addConnectors([connectorName], [connectorInstanace.address]);

  getAddress(String(process.env.networkType)).connectors[connectorName] =
    connectorInstanace.address;
  abis.connectors[connectorName] = contractArtifact.abi;

  return connectorInstanace;
}
