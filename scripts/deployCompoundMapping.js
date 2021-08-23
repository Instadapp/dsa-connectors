const hre = require("hardhat");
const { ethers } = hre;

async function main() {

  const CONNECTORS_V2 = "0x97b0B3A8bDeFE8cB9563a3c610019Ad10DB8aD11";

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
    "WBTC-B": "0xccF4429DB6322D5C611ee964527D42E5d685DD6a",
    "ZRX-A": "0xb3319f5d18bc0d84dd1b4825dcde5d5f7266d407",
    "YFI-A": "0x80a2ae356fc9ef4305676f7a3e2ed04e12c33946",
    "SUSHI-A": "0x4b0181102a0112a2ef11abee5563bb4a3176c9d7",
    "MKR-A": "0x95b4ef2869ebd94beb4eee400a99824bf5dc325b",
    "AAVE-A": "0xe65cdb6479bac1e22340e4e755fae7e509ecd06c",
    "TUSD-A": "0x12392f67bdf24fae0af363c24ac620a2f67dad86",
    "LINK-A": "0xface851a4921ce59e912d19329929ce6da6eb0c7",
  }

  const tokenMapping = {
    "ETH-A": "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
    "BAT-A": "0x0D8775F648430679A709E98d2b0Cb6250d2887EF",
    "COMP-A": "0xc00e94cb662c3520282e6f5717214004a7f26888",
    "DAI-A": "0x6b175474e89094c44da98b954eedeac495271d0f",
    "REP-A": "0x1985365e9f78359a9B6AD760e32412f4a445E862",
    "UNI-A": "0x1f9840a85d5af5bf1d1762f925bdaddc4201f984",
    "USDC-A": "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    "USDT-A": "0xdac17f958d2ee523a2206206994597c13d831ec7",
    "WBTC-A": "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
    "WBTC-B": "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
    "ZRX-A": "0xe41d2489571d322189246dafa5ebde1f4699f498",
    "YFI-A": "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e",
    "SUSHI-A": "0x6B3595068778DD592e39A122f4f5a5cF09C90fE2",
    "MKR-A": "0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2",
    "AAVE-A": "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9",
    "TUSD-A": "0x0000000000085d4780B73119b644AE5ecd22b376",
    "LINK-A": "0x514910771af9ca656af840dff83e8264ecf986ca",
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