import { Provider } from "@ethersproject/abstract-provider";
import { Signer } from "@ethersproject/abstract-signer";
import { ethers } from "hardhat";
import { impersonateAccounts } from "./impersonate";

const mineTx = async (tx: any) => {
  await (await tx).wait();
};

const tokenMapping: Record<string, any> = {
  usdc: {
    impersonateSigner: "0xfcb19e6a322b27c06842a71e8c725399f049ae3a",
    address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    abi: [
      "function mint(address _to, uint256 _amount) external returns (bool);",
    ],
    process: async function(owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);

      await mineTx(contract.mint(to, amt));
    },
  },
  dai: {
    impersonateSigner: "0x47ac0fb4f2d84898e4d9e7b4dab3c24507a6d503",
    abi: ["function transfer(address to, uint value)"],
    address: "0x6b175474e89094c44da98b954eedeac495271d0f",
    process: async function(owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.transfer(to, amt));
    },
  },
  usdt: {
    impersonateSigner: "0xc6cde7c39eb2f0f0095f41570af89efc2c1ea828",
    address: "0xdac17f958d2ee523a2206206994597c13d831ec7",
    abi: [
      "function issue(uint amount)",
      "function transfer(address to, uint value)",
    ],
    process: async function(owner: Signer | Provider, address: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);

      await mineTx(contract.issue(amt));
      await mineTx(contract.transfer(address, amt));
    },
  },
  wbtc: {
    impersonateSigner: "0xCA06411bd7a7296d7dbdd0050DFc846E95fEBEB7",
    address: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
    abi: ["function mint(address _to, uint256 _amount) public returns (bool)"],
    process: async function(owner: Signer | Provider, address: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.mint(address, amt));
    },
  },
  inst: {
    impersonateSigner: "0x75e89d5979E4f6Fba9F97c104c2F0AFB3F1dcB88",
    address: "0x6f40d4a6237c257fff2db00fa0510deeecd303eb",
    abi: ["function transfer(address to, uint value)"],
    process: async function(owner: Signer | Provider, address: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.transfer(address, amt));
    },
  },
};

export async function addLiquidity(tokenName: string, address: any, amt: any) {
  const [signer] = await ethers.getSigners();
  tokenName = tokenName.toLowerCase();
  if (!tokenMapping[tokenName]) {
    throw new Error(
      `Add liquidity doesn't support the following token: ${tokenName}`
    );
  }

  const token = tokenMapping[tokenName];

  const [impersonatedSigner] = await impersonateAccounts([
    token.impersonateSigner,
  ]);

  // send 1 eth to cover any tx costs.
  await signer.sendTransaction({
    to: impersonatedSigner.address,
    value: ethers.utils.parseEther("1"),
  });

  await token.process(impersonatedSigner, address, amt);
}
