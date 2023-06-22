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
    decimals: 18
  },
  dai: {
    type: "token",
    symbol: "DAI",
    name: "DAI Stable",
    address: "0xd586e7f844cea2f87f50152665bcbc2c279d8d70",
    decimals: 18
  },
  usdc: {
    type: "token",
    symbol: "USDC",
    name: "USD Coin",
    address: "0xa7d7079b0fead91f3e65f86e8915cb59c1a4c664",
    decimals: 6
  },
  weth: {
    type: "token",
    symbol: "WETH",
    name: "Wrapped ETH",
    address: "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
    decimals: 6
  }
};

export const tokenMapping: Record<string, any> = {
  usdc: {
    impersonateSigner: "0xce2cc46682e9c6d5f174af598fb4931a9c0be68e",
    address: "0xa7d7079b0fead91f3e65f86e8915cb59c1a4c664",
    abi: ["function mint(address _to, uint256 _amount) external returns (bool);"],
    process: async function (owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);

      await mineTx(contract.mint(to, amt));
    }
  },
  dai: {
    impersonateSigner: "0xc5ed2333f8a2c351fca35e5ebadb2a82f5d254c3",
    abi: ["function transfer(address to, uint value)"],
    address: "0xd586e7f844cea2f87f50152665bcbc2c279d8d70",
    process: async function (owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.transfer(to, amt));
    }
  }
};
