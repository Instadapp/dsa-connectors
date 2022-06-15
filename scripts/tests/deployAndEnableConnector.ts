import { addresses as addressesPolygon } from "./polygon/addresses";
import { addresses } from "./mainnet/addresses";
import { abis } from "../constant/abis";
import { addresses as addressesArbitrum } from "./arbitrum/addresses";
import { addresses as addressesAvalanche } from "./avalanche/addresses";
import { addresses as addressesOptimism } from "./optimism/addresses";
import { addresses as addressesFantom } from "./fantom/addresses";

import hre from "hardhat";
import type { Signer, Contract } from "ethers";
import type { ContractJSON } from "ethereum-waffle/dist/esm/ContractJSON";

const { ethers, waffle } = hre;
const { deployContract } = waffle;

interface DeployInterface {
  connectorName: string;
  contractArtifact: ContractJSON;
  signer: Signer;
  connectors: Contract;
}

function getAddress(network: string | undefined) {
  if (network === "polygon") return addressesPolygon;
  else if (network === "arbitrum") return addressesArbitrum;
  else if (network === "avalanche") return addressesAvalanche;
  else if (network === "optimism") return addressesOptimism;
  else if (network === "fantom") return addressesFantom;
  else return addresses;
}

export async function deployAndEnableConnector(
  {
    connectorName,
    contractArtifact,
    signer,
    connectors
  } : DeployInterface
) {
  const connectorInstanace: Contract = await deployContract(signer, contractArtifact);

  await connectors
    .connect(signer)
    .addConnectors([connectorName], [connectorInstanace.address]);

  getAddress(String(process.env.networkType)).connectors[connectorName] =
    connectorInstanace.address;
  abis.connectors[connectorName] = contractArtifact.abi;

  return connectorInstanace;
}
