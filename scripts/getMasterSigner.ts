import { ethers, network } from "hardhat";
import { addresses } from "./constant/addresses";
import { abis } from "./constant/abis";

export async function getMasterSigner() {
  const [_, __, ___, wallet3] = await ethers.getSigners();
  const instaIndex = new ethers.Contract(
    addresses.core.instaIndex,
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
