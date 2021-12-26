import { ethers } from "hardhat";
import { deployConnector } from "./deployConnector";
import { connectMapping } from "./connectors";

async function main() {
  if (process.env.connectorName) {
    await deployConnector();
  } else {
    const addressMapping: Record<string, string> = {};

    for (const key in connectMapping) {
      addressMapping[key] = await deployConnector(connectMapping[key]);
    }
    console.log(addressMapping);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
