import hre, { ethers } from "hardhat";
import { IERC20Minimal__factory } from "../../../typechain";
import { BigNumber as BN } from "ethers";

export const DEAD_ADDRESS = "0x0000000000000000000000000000000000000001";
export const ZERO_ADDRESS = ethers.constants.AddressZero;

export const DEFAULT_DECIMALS = 18;

export const ZERO = BN.from(0);
export const ONE_MIN = BN.from(60);
export const TEN_MINS = BN.from(60 * 10);
export const ONE_HOUR = BN.from(60 * 60);
export const ONE_DAY = BN.from(60 * 60 * 24);
export const FIVE_DAYS = BN.from(60 * 60 * 24 * 5);
export const TEN_DAYS = BN.from(60 * 60 * 24 * 10);
export const ONE_WEEK = BN.from(60 * 60 * 24 * 7);
export const ONE_YEAR = BN.from(60 * 60 * 24 * 365);

export const connectorName = "MStable";

interface TokenData {
  tokenAddress: string;
  tokenWhaleAddress?: string;
  feederPool?: string;
}

export const toEther = (amount: BN) => ethers.utils.formatEther(amount);

export const getToken = (tokenSymbol: string): TokenData => {
  switch (tokenSymbol) {
    case "MTA":
      return {
        tokenAddress: "0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2"
      };
    case "mUSD":
      return {
        tokenAddress: "0xe2f2a5c287993345a840db3b0845fbc70f5935a5",
        tokenWhaleAddress: "0x503828976D22510aad0201ac7EC88293211D23Da"
      };

    case "DAI":
      return {
        tokenAddress: "0x6b175474e89094c44da98b954eedeac495271d0f",
        tokenWhaleAddress: "0xF977814e90dA44bFA03b6295A0616a897441aceC"
      };
    case "USDC":
      return {
        tokenAddress: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
      };
    case "imUSD":
      return {
        tokenAddress: "0x30647a72dc82d7fbb1123ea74716ab8a317eac19"
      };

    case "imUSDVault":
      return {
        tokenAddress: "0x78BefCa7de27d07DC6e71da295Cc2946681A6c7B"
      };

    // Feeder Asset
    case "alUSD":
      return {
        tokenAddress: "0xbc6da0fe9ad5f3b0d58160288917aa56653660e9",
        tokenWhaleAddress: "0x115f95c00e8cf2f5C57250caA555A6B4e50B446b",
        feederPool: "0x4eaa01974B6594C0Ee62fFd7FEE56CF11E6af936"
      };

    default:
      throw new Error(`Token ${tokenSymbol} not supported`);
  }
};

export const sendToken = async (token: string, amount: any, from: string, to: string): Promise<any> => {
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [from]
  });
  const [signer] = await ethers.getSigners();
  const sender = hre.ethers.provider.getSigner(from);

  await signer.sendTransaction({
    to: from,
    value: ethers.utils.parseEther("1")
  });

  return await IERC20Minimal__factory.connect(token, sender).transfer(to, amount);
};

export const fundWallet = async (token: string, amount: any, to: string) => {
  const { tokenAddress, tokenWhaleAddress } = getToken(token);
  await sendToken(tokenAddress, amount, tokenWhaleAddress!, to);
};

export const calcMinOut = (amount: BN, slippage: number): BN => {
  const value = simpleToExactAmount(1 - slippage);
  const minOut = amount.mul(value).div(ethers.BigNumber.from(10).pow(DEFAULT_DECIMALS));
  return minOut;
};

export const simpleToExactAmount = (amount: number | string | BN, decimals: number | BN = DEFAULT_DECIMALS): BN => {
  let amountString = amount.toString();
  const decimalsBN = BN.from(decimals);

  if (decimalsBN.gt(100)) {
    throw new Error(`Invalid decimals amount`);
  }

  const scale = BN.from(10).pow(decimals);
  const scaleString = scale.toString();

  // Is it negative?
  const negative = amountString.substring(0, 1) === "-";
  if (negative) {
    amountString = amountString.substring(1);
  }

  if (amountString === ".") {
    throw new Error(`Error converting number ${amountString} to precise unit, invalid value`);
  }

  // Split it into a whole and fractional part
  // eslint-disable-next-line prefer-const
  let [whole, fraction, ...rest] = amountString.split(".");
  if (rest.length > 0) {
    throw new Error(`Error converting number ${amountString} to precise unit, too many decimal points`);
  }

  if (!whole) {
    whole = "0";
  }
  if (!fraction) {
    fraction = "0";
  }

  if (fraction.length > scaleString.length - 1) {
    throw new Error(`Error converting number ${amountString} to precise unit, too many decimal places`);
  }

  while (fraction.length < scaleString.length - 1) {
    fraction += "0";
  }

  const wholeBN = BN.from(whole);
  const fractionBN = BN.from(fraction);
  let result = wholeBN.mul(scale).add(fractionBN);

  if (negative) {
    result = result.mul("-1");
  }

  return result;
};

export const advanceBlock = async (): Promise<void> => ethers.provider.send("evm_mine", []);

export const increaseTime = async (length: BN | number): Promise<void> => {
  await ethers.provider.send("evm_increaseTime", [BN.from(length).toNumber()]);
  await advanceBlock();
};
