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
    aTokenAddress: "0x030bA81f1c18d280636F32af80b9AAd02Cf0854e",
    cTokenAddress: "0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5",
    decimals: 18
  },
  dai: {
    type: "token",
    symbol: "DAI",
    name: "DAI Stable",
    address: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
    aTokenAddress: "0x028171bCA77440897B824Ca71D1c56caC55b68A3",
    cTokenAddress: "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643",
    decimals: 18
  },
  usdc: {
    type: "token",
    symbol: "USDC",
    name: "USD Coin",
    address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    aTokenAddress: "0xBcca60bB61934080951369a648Fb03DF4F96263C",
    cTokenAddress: "0x39AA39c021dfbaE8faC545936693aC917d5E7563",
    decimals: 6
  },
  weth: {
    type: "token",
    symbol: "WETH",
    name: "Wrapped Ether",
    address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    aTokenAddress: "0x030bA81f1c18d280636F32af80b9AAd02Cf0854e",
    cTokenAddress: "0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5",
    decimals: 18
  },
  ens: {
    type: "token",
    symbol: "ENS",
    name: "Etherem Name Services",
    address: "0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72",
    aTokenAddress: "0x9a14e23A58edf4EFDcB360f68cd1b95ce2081a2F",
    decimals: 18
  },
  comp: {
    type: "token",
    symbol: "COMP",
    name: "Compound",
    address: "0xc00e94Cb662C3520282E6f5717214004A7f26888",
    cTokenAddress: "0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4",
    decimals: 18
  },
  link: {
    type: "token",
    symbol: "LINK",
    name: "ChainLink Token",
    address: "0x514910771AF9Ca656af840dff83E8264EcF986CA",
    aTokenAddress: "0xa06bC25B5805d5F8d82847D191Cb4Af5A3e873E0",
    cTokenAddress: "0xFAce851a4921ce59e912d19329929CE6da6EB0c7",
    decimals: 18
  },
  uni: {
    type: "token",
    symbol: "UNI",
    name: "Uniswap",
    address: "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984",
    aTokenAddress: "0xB9D7CB55f463405CDfBe4E90a6D2Df01C2B92BF1",
    cTokenAddress: "0x35A18000230DA775CAc24873d00Ff85BccdeD550",
    decimals: 18
  },
  crvusd: {
    type: "token",
    symbol: "crvUSD",
    name: "Curve.Fi USD Stablecoin",
    address: "0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E",
    decimals: 18
  },
  sfrxeth: {
    type: "token",
    symbol: "sfrxETH",
    name: "Staked Frax Ether",
    address: "0xac3E018457B222d93114458476f3E3416Abbe38F",
    decimals: 18
  },
  wsteth: {
    type: "token",
    symbol: "wstETH",
    name: "Wrapped liquid staked Ether 2.0",
    address: "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0",
    decimals: 18
  },
  wbtc: {
    type: "token",
    symbol: "WBTC",
    name: "Wrapped BTC",
    address: "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
    decimals: 8
  },
};

export const dsaMaxValue = "115792089237316195423570985008687907853269984665640564039457584007913129639935";

export const tokenMapping: Record<string, any> = {
  usdc: {
    impersonateSigner: "0xfcb19e6a322b27c06842a71e8c725399f049ae3a",
    address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    abi: [
      "function mint(address _to, uint256 _amount) external returns (bool)",
      "function balanceOf(address user) external returns (uint256)"
    ],
    process: async function (owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);

      await mineTx(contract.mint(to, amt));
    }
  },
  dai: {
    impersonateSigner: "0x47ac0fb4f2d84898e4d9e7b4dab3c24507a6d503",
    abi: ["function transfer(address to, uint value)"],
    address: "0x6b175474e89094c44da98b954eedeac495271d0f",
    process: async function (owner: Signer | Provider, to: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.transfer(to, amt));
    }
  },
  usdt: {
    impersonateSigner: "0xc6cde7c39eb2f0f0095f41570af89efc2c1ea828",
    address: "0xdac17f958d2ee523a2206206994597c13d831ec7",
    abi: ["function issue(uint amount)", "function transfer(address to, uint value)"],
    process: async function (owner: Signer | Provider, address: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);

      await mineTx(contract.issue(amt));
      await mineTx(contract.transfer(address, amt));
    }
  },
  wbtc: {
    impersonateSigner: "0xCA06411bd7a7296d7dbdd0050DFc846E95fEBEB7",
    address: "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599",
    abi: ["function mint(address _to, uint256 _amount) public returns (bool)"],
    process: async function (owner: Signer | Provider, address: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.mint(address, amt));
    }
  },
  inst: {
    impersonateSigner: "0x75e89d5979E4f6Fba9F97c104c2F0AFB3F1dcB88",
    address: "0x6f40d4a6237c257fff2db00fa0510deeecd303eb",
    abi: ["function transfer(address to, uint value)"],
    process: async function (owner: Signer | Provider, address: any, amt: any) {
      const contract = new ethers.Contract(this.address, this.abi, owner);
      await mineTx(contract.transfer(address, amt));
    }
  }
};
