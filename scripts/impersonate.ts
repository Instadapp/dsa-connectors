import { ethers, network } from "hardhat";

export const impersonateAccounts = async (accounts: any) => {
  const signers = [];
  for (const account of accounts) {
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [account],
    });

    signers.push(await ethers.getSigner(account));
  }
  return signers;
};
