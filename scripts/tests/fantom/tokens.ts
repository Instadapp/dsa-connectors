import { Provider } from "@ethersproject/abstract-provider";
import { Signer } from "@ethersproject/abstract-signer";
import { ethers } from "hardhat";

const mineTx = async (tx: any) => {
  await (await tx).wait();
};

export const tokens = {
  ftm: {
    type: "token",
    symbol: "FTM",
    name: "Fantom",
    address: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    decimals: 18,
  },
  dai: {
    type: "token",
    symbol: "DAI",
    name: "DAI Stable",
    address: "0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E",
    decimals: 18,
  },
  usdc: {
    type: "token",
    symbol: "USDC",
    name: "USD Coin",
    address: "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75",
    decimals: 6,
  },
};

export const tokenMapping: Record<string, any> = {
  usdc: {
    impersonateSigner: "0x4188663a85C92EEa35b5AD3AA5cA7CeB237C6fe9",
    address: "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75",
    abi: [
      "function mint(address _to, uint256 _amount) external returns (bool);",
    ],
    process: async function (owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);

      await mineTx(contract.mint(to, amt));
    },
  },
  dai: {
    impersonateSigner: "0x9bdB521a97E95177BF252C253E256A60C3e14447",
    address: "0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E",
    abi: ["function transfer(address to, uint value)"],
    process: async function (owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.transfer(to, amt));
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
