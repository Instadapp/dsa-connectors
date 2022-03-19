import { Contract } from "@ethersproject/contracts";
import { ethers } from "hardhat";

import { Greeter__factory } from "../../typechain";

async function main(): Promise<void> {
  const Greeter: Greeter__factory = await ethers.getContractFactory("Greeter");
  const greeter: Contract = await Greeter.deploy("Hello, Buidler!");
  await greeter.deployed();

  console.log("Greeter deployed to: ", greeter.address);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
