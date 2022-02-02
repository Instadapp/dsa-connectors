import { Provider } from "@ethersproject/abstract-provider";
import { Signer } from "@ethersproject/abstract-signer";
import { ethers } from "hardhat";

const mineTx = async (tx: any) => {
  await (await tx).wait();
};

export const tokens = {
  eth: {
    type: "token",
    symbol: "ETH",
    name: "Ethereum",
    address: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    decimals: 18,
  },
  dai: {
    type: "token",
    symbol: "DAI",
    name: "DAI Stable",
    address: "0xd586e7f844cea2f87f50152665bcbc2c279d8d70",
    decimals: 18,
  },
  usdc: {
    type: "token",
    symbol: "USDC",
    name: "USD Coin",
    address: "0xa7d7079b0fead91f3e65f86e8915cb59c1a4c664",
    decimals: 6,
  },
};

export const tokenMapping: Record<string, any> = {
  usdc: {
    impersonateSigner: "0xc5ed2333f8a2c351fca35e5ebadb2a82f5d254c3",
    address: "0xa7d7079b0fead91f3e65f86e8915cb59c1a4c664",
    abi: [
      "function mint(address _to, uint256 _amount) external returns (bool);",
    ],
    process: async function (owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);

      await mineTx(contract.mint(to, amt));
    },
  },
  dai: {
    impersonateSigner: "0xed2a7edd7413021d440b09d654f3b87712abab66",
    address: "0xd586e7f844cea2f87f50152665bcbc2c279d8d70",
    abi: ["function transfer(address to, uint value)"],
    process: async function (owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.transfer(to, amt));
    },
  },
  usdt: {
    impersonateSigner: "0xc5ed2333f8a2c351fca35e5ebadb2a82f5d254c3",
    address: "0xc7198437980c041c805a1edcba50c1ce5db95118",
    abi: [
      "function issue(uint amount)",
      "function transfer(address to, uint value)",
    ],
    process: async function (owner: Signer | Provider, address: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);

      await mineTx(contract.issue(amt));
      await mineTx(contract.transfer(address, amt));
    },
  },
  wbtc: {
    impersonateSigner: "0x63cdb19c13497383726ad6bbf7c6b6cf725a3164",
    address: "0x50b7545627a5162f82a992c33b87adc75187b218",
    abi: ["function mint(address _to, uint256 _amount) public returns (bool)"],
    process: async function (owner: Signer | Provider, address: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.mint(address, amt));
    },
  },
  // inst: {
  //   impersonateSigner: "0x75e89d5979E4f6Fba9F97c104c2F0AFB3F1dcB88",
  //   address: "0x6f40d4a6237c257fff2db00fa0510deeecd303eb",
  //   abi: ["function transfer(address to, uint value)"],
  //   process: async function (owner: Signer | Provider, address: any, amt: any) {
  //     const contract = new ethers.Contract(this.address, this.abi, owner);
  //     await mineTx(contract.transfer(address, amt));
  //   },
  // },
};
