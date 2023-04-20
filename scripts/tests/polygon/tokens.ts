import { Provider } from "@ethersproject/abstract-provider";
import { Signer } from "@ethersproject/abstract-signer";
import { ethers } from "hardhat";

const mineTx = async (tx: any) => {
  await (await tx).wait();
};

export const tokens = {
  matic: {
    type: "token",
    symbol: "MATIC",
    name: "Matic",
    address: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    decimals: 18,
  },
  wmatic: {
    type: "token",
    symbol: "WMATIC",
    name: "Wrapped Matic",
    address: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
    decimals: 18,
  },
  eth: {
    type: "token",
    symbol: "ETH",
    name: "Ethereum",
    address: "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
    decimals: 18,
  },
  dai: {
    type: "token",
    symbol: "DAI",
    name: "DAI Stable",
    address: "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
    decimals: 18,
  },
  usdc: {
    type: "token",
    symbol: "USDC",
    name: "USD Coin",
    address: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
    decimals: 6,
  },
};

export const tokenMapping: Record<string, any> = {
  usdc: {
    impersonateSigner: "0x6e7a5fafcec6bb1e78bae2a1f0b612012bf14827",
    address: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
    abi: [
      "function mint(address _to, uint256 _amount) external returns (bool);",
    ],
    process: async function (owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);

      await mineTx(contract.mint(to, amt));
    },
  },
  dai: {
    impersonateSigner: "0x4a35582a710e1f4b2030a3f826da20bfb6703c09",
    address: "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
    abi: ["function transfer(address to, uint value)"],
    process: async function (owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.transfer(to, amt));
    },
  },
  usdt: {
    impersonateSigner: "0x0d0707963952f2fba59dd06f2b425ace40b492fe",
    address: "0xc2132d05d31c914a87c6611c10748aeb04b58e8f",
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
    impersonateSigner: "0xdc9232e2df177d7a12fdff6ecbab114e2231198d",
    address: "0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6",
    abi: ["function mint(address _to, uint256 _amount) public returns (bool)"],
    process: async function (owner: Signer | Provider, address: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.mint(address, amt));
    },
  },
  inst: {
    impersonateSigner: "0xf1f22f25f748f79263d44735198e023b72806ab1",
    address: "0xf50d05a1402d0adafa880d36050736f9f6ee7dee",
    abi: ["function transfer(address to, uint value)"],
    process: async function (owner: Signer | Provider, address: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.transfer(address, amt));
    },
  },
};
