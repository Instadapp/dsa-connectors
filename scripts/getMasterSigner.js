const hre = require("hardhat");
const { ethers, waffle } = hre;
const addresses = require("./constant/addresses");
const abis = require("./constant/abis");
const { provider, deployContract } = waffle


module.exports = async function () {
    const instaIndex = await ethers.getContractAt(abis.core.instaIndex, addresses.core.instaIndex)

    const masterAddress = await instaIndex.master(); // TODO: make it constant?
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [ masterAddress]
    })
    const [wallet0, wallet1, wallet2, wallet3] = await ethers.getSigners()
    await wallet3.sendTransaction({
        to: masterAddress,
        value: ethers.utils.parseEther("10")
      });

    return await ethers.getSigner(masterAddress);
};
