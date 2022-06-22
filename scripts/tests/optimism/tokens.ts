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
    name: "Eth",
    address: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
    decimals: 18
  },
  dai: {
    type: "token",
    symbol: "DAI",
    name: "DAI Stable",
    address: "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063",
    decimals: 18
  },
  usdc: {
    type: "token",
    symbol: "USDC",
    name: "USD Coin",
    address: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
    decimals: 6
  },
  usdt: {
    type: "token",
    symbol: "USDT",
    name: "Tether USD Coin",
    address: "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58",
    decimals: 6
  }
};

export const tokenMapping: Record<string, any> = {
  usdc: {
    impersonateSigner: "0x31efc4aeaa7c39e54a33fdc3c46ee2bd70ae0a09",
    address: "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
    abi: ["function mint(address _to, uint256 _amount) external returns (bool);"],
    process: async function (owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);

      await mineTx(contract.mint(to, amt));
    }
  },
  dai: {
    impersonateSigner: "0x360537542135943E8Fc1562199AEA6d0017F104B",
    address: "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1",
    abi: ["function transfer(address to, uint value)"],
    process: async function (owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.transfer(to, amt));
    }
  },
  usdt: {
    impersonateSigner: "0xc858a329bf053be78d6239c4a4343b8fbd21472b",
    address: "0x94b008aA00579c1307B0EF2c499aD98a8ce58e58",
    abi: ["function issue(uint amount)", "function transfer(address to, uint value)"],
    process: async function (owner: Signer | Provider, address: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.issue(amt));
      await mineTx(contract.transfer(address, amt));
    }
  },
  wbtc: {
    impersonateSigner: "0x3aa76aa74bdfa09d68d9ebeb462c5f40d727283f",
    address: "0x68f180fcCe6836688e9084f035309E29Bf0A2095",
    abi: ["function mint(address _to, uint256 _amount) public returns (bool)"],
    process: async function (owner: Signer | Provider, address: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.mint(address, amt));
    }
  }
  // inst: {
  //   impersonateSigner: "0xf1f22f25f748f79263d44735198e023b72806ab1",
  //   address: "0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb",
  //   abi: ["function transfer(address to, uint value)"],
  //   process: async function (owner: Signer | Provider, address: any, amt: any) {
  //     const contract = new ethers.Contract(this.address, this.abi, owner);
  //     await mineTx(contract.transfer(address, amt));
  //   },
  // },
};
