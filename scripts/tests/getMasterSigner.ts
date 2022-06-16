import { ethers, network } from "hardhat";
import { addresses } from "./mainnet/addresses";
import { addresses as addressesPolygon } from "./polygon/addresses";
import { addresses as addressesArbitrum } from "./arbitrum/addresses";
import { addresses as addressesAvalanche } from "./avalanche/addresses";
import { addresses as addressesOptimism } from "./optimism/addresses";
import { addresses as addressesFantom } from "./fantom/addresses";
import { abis } from "../constant/abis";

function getAddress(network: string | undefined) {
  if (network === "polygon") return addressesPolygon.core.instaIndex;
  else if (network === "arbitrum") return addressesArbitrum.core.instaIndex;
  else if (network === "avalanche") return addressesAvalanche.core.instaIndex;
  else if (network === "optimism") return addressesOptimism.core.instaIndex;
  else if (network === "fantom") return addressesFantom.core.instaIndex;
  else return addresses.core.instaIndex;
}

export async function getMasterSigner() {
  const [_, __, ___, wallet3] = await ethers.getSigners();
  const instaIndex = new ethers.Contract(
    getAddress(String(process.env.networkType)),
    abis.core.instaIndex,
    wallet3
  );

  const masterAddress = await instaIndex.master();
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [masterAddress],
  });

  await network.provider.send("hardhat_setBalance", [
    masterAddress,
    "0x8ac7230489e80000", // 1e19 wei
  ]);

  return await ethers.getSigner(masterAddress);
}
