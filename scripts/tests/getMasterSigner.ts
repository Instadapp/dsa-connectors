import { ethers, network } from "hardhat";
import { addresses } from "./mainnet/addresses";
import { addresses as addressesPolygon } from "./polygon/addresses";
import { abis } from "../constant/abis";

function getAddress(network: string | undefined) {
  if (network === "polygon") return addressesPolygon.core.instaIndex;
  // else if (network === "arbitrum") return addressesPolygon.core.instaIndex;
  // else if (network === "avalanche") return addressesPolygon.core.instaIndex;
  else return addresses.core.instaIndex;
}

export async function getMasterSigner() {
  const [_, __, ___, wallet3] = await ethers.getSigners();
  const instaIndex = new ethers.Contract(
    getAddress(String(process.env.networkType)),
    abis.core.instaIndex,
    wallet3
  );

  const masterAddress = await instaIndex.master(); // TODO: make it constant?
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [masterAddress],
  });
  await wallet3.sendTransaction({
    to: masterAddress,
    value: ethers.utils.parseEther("10"),
  });

  return await ethers.getSigner(masterAddress);
}
