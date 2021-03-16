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

  const tokenMapping = {
    "ETH-A": "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
    "BAT-A": "0x0D8775F648430679A709E98d2b0Cb6250d2887EF",
    "COMP-A": "0xc00e94cb662c3520282e6f5717214004a7f26888",
    "DAI-A": "0x6b175474e89094c44da98b954eedeac495271d0f",
    "REP-A": "0x1985365e9f78359a9B6AD760e32412f4a445E862",
    "UNI-A": "0x221657776846890989a759ba2973e427dff5c9bb",
    "USDC-A": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    "USDT-A": "0xdac17f958d2ee523a2206206994597c13d831ec7",
    "WBTC-A": "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
    "ZRX-A": "0xe41d2489571d322189246dafa5ebde1f4699f498"
  }

  const Mapping = await ethers.getContractFactory("InstaCompoundMapping");
  const mapping = await Mapping.deploy(
    CONNECTORS_V2,
    Object.keys(ctokenMapping),
    Object.values(tokenMapping),
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
          Object.values(tokenMapping),
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