import { ethers } from "hardhat";

const network = String(process.env.networkType);

import { addressesPolygon } from "./polygon/addressesPolygon";
import { addresses } from "./mainnet/addresses";
import { abis } from "../constant/abis";
import { abi } from "../../deployements/mainnet/Implementation_m1.sol/InstaImplementationM1.json";

function getAddress(network: string | undefined) {
  if (network === "polygon") return addressesPolygon.core.instaIndex;
  // else if (network === "arbitrum") return addressesPolygon.core.instaIndex;
  // else if (network === "avalanche") return addressesPolygon.core.instaIndex;
  else return addresses.core.instaIndex;
}

export async function buildDSAv2(owner: any) {
  const instaIndex = await ethers.getContractAt(
    abis.core.instaIndex,
    getAddress(String(process.env.networkType))
  );

  const tx = await instaIndex.build(owner, 2, owner);
  const receipt = await tx.wait();
  const event = receipt.events.find(
    (a: { event: string }) => a.event === "LogAccountCreated"
  );
  return await ethers.getContractAt(abi, event.args.account);
}
