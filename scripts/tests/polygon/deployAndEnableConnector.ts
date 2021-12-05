import "@nomiclabs/hardhat-waffle";

import { addresses } from "./constant/addresses";
import { abis } from "../../constant/abis";

import * as hre from "hardhat";
const { ethers, waffle } = hre;
const { deployContract } = waffle;

module.exports = async function({
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
};
