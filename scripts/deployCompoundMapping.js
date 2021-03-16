const hre = require("hardhat");
const { ethers } = hre;

async function main() {

  // TODO - Replace with actual contract address after deployment
  const CONNECTORS_V2 = "0x2971AdFa57b20E5a416aE5a708A8655A9c74f723";

  const ctokenMapping = {
    "ETH-A": "0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5",
    "BAT-A": "0x6c8c6b02e7b2be14d4fa6022dfd6d75921d90e4e",
    "COMP-A": "0x70e36f6bf80a52b3b46b3af8e106cc0ed743e8e4",
    "DAI-A": "0x5d3a536e4d6dbd6114cc1ead35777bab948e3643",
    "REP-A": "0x158079ee67fce2f58472a96584a73c7ab9ac95c1",
    "UNI-A": "0x35a18000230da775cac24873d00ff85bccded550",
    "USDC-A": "0x39aa39c021dfbae8fac545936693ac917d5e7563",
    "USDT-A": "0xf650c3d88d12db855b8bf7d11be6c55a4e07dcc9",
    "WBTC-A": "0xc11b1268c1a384e55c48c2391d8d480264a3a7f4",
    "ZRX-A": "0xb3319f5d18bc0d84dd1b4825dcde5d5f7266d407"
  }

  const Mapping = await ethers.getContractFactory("InstaCompoundMapping");
  const mapping = await Mapping.deploy(
    CONNECTORS_V2,
    Object.keys(ctokenMapping),
    Object.values(ctokenMapping)
  );
  await mapping.deployed();

  console.log(`InstaCompoundMapping Deployed: ${mapping.address}`);

  try {
    await hre.run("verify:verify", {
        address: mapping.address,
        constructorArguments: [
          CONNECTORS_V2,
          Object.keys(ctokenMapping),
          Object.values(ctokenMapping)
        ]
      }
    )
} catch (error) {
    console.log(`Failed to verify: InstaCompoundMapping@${mapping.address}`)
    console.log(error)
    console.log()
}
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });