import { ethers } from "hardhat";

import { addresses } from "./constant/addresses";
import { abis } from "./constant/abis";
import {abi} from "../deployements/mainnet/Implementation_m1.sol/InstaImplementationM1.json";

export default async function (owner: any) {
    const instaIndex = await ethers.getContractAt(abis.core.instaIndex, addresses.core.instaIndex)

    const tx = await instaIndex.build(owner, 2, owner);
    const receipt = await tx.wait()
    const event = receipt.events.find((a: { event: string; }) => a.event === "LogAccountCreated")
    return await ethers.getContractAt(abi, event.args.account)
};

