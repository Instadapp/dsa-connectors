import hre from "hardhat";
import { ethers } from "hardhat";
import { assert, expect } from "chai";

import {
  DEFAULT_DECIMALS,
  DEAD_ADDRESS,
  toEther,
  connectorName,
  simpleToExactAmount,
  getToken
} from "./mstable.helpers";

import { IERC20Minimal, IERC20Minimal__factory } from "../../../typechain";
import { BigNumber, Contract, Wallet } from "ethers";

import { encodeSpells } from "../../../scripts/tests/encodeSpells";

const provider = hre.waffle.provider;

let imUsdToken: IERC20Minimal = IERC20Minimal__factory.connect(getToken("imUSD").tokenAddress, provider);
let imUsdVault: IERC20Minimal = IERC20Minimal__factory.connect(getToken("imUSDVault").tokenAddress, provider);

export const executeAndAssertSwap = async (
  method: string,
  tokenFrom: IERC20Minimal,
  tokenFromDecimals: number,
  tokenTo: IERC20Minimal,
  tokenToDecimals: number,
  swapAmount: BigNumber,
  dsaWallet0: Contract,
  wallet0: Wallet,
  args?: any[]
) => {
  const diffFrom = ethers.BigNumber.from(10).pow(DEFAULT_DECIMALS - tokenFromDecimals);
  const diffTo = ethers.BigNumber.from(10).pow(DEFAULT_DECIMALS - tokenToDecimals);

  const tokenFromBalanceBefore = (await tokenFrom.balanceOf(dsaWallet0.address)).mul(diffFrom);
  console.log("Token From balance before: ", toEther(tokenFromBalanceBefore));

  const tokenToBalanceBefore = (await tokenTo.balanceOf(dsaWallet0.address)).mul(diffTo);
  console.log("Token To balance before: ", toEther(tokenToBalanceBefore));

  const spells = [
    {
      connector: connectorName,
      method,
      args: [tokenFrom.address, tokenTo.address, swapAmount, 1, ...(args ? args : []), 0, 0]
    }
  ];

  console.log("Swapping...", toEther(swapAmount));

  const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), DEAD_ADDRESS);

  const tokenFromBalanceAfter = (await tokenFrom.balanceOf(dsaWallet0.address)).mul(diffFrom);
  console.log("Token From balance after: ", toEther(tokenFromBalanceAfter));

  const tokenToBalanceAfter = (await tokenTo.balanceOf(dsaWallet0.address)).mul(diffTo);
  console.log("Token To balance after: ", toEther(tokenToBalanceAfter));

  expect(tokenFromBalanceAfter).to.be.eq(tokenFromBalanceBefore.sub(swapAmount));
  expect(tokenToBalanceAfter).to.be.gt(tokenToBalanceBefore);
};

export const executeAndAssertDeposit = async (
  method: string,
  tokenFrom: IERC20Minimal,
  depositAmount: BigNumber,
  dsaWallet0: Contract,
  wallet0: Wallet,
  args?: any[]
) => {
  const FromBalanceBefore = await tokenFrom.balanceOf(dsaWallet0.address);
  console.log("Balance before: ", toEther(FromBalanceBefore));

  const imUsdVaultBalanceBefore = await imUsdVault.balanceOf(dsaWallet0.address);
  console.log("imUSD Vault balance before: ", toEther(imUsdVaultBalanceBefore));

  const spells = [
    {
      connector: connectorName,
      method,
      args: [tokenFrom.address, depositAmount, ...(args ? args : []), 0, 0]
    }
  ];

  const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), DEAD_ADDRESS);

  const FromBalanceAfter = await tokenFrom.balanceOf(dsaWallet0.address);
  console.log("Balance after: ", toEther(FromBalanceAfter));

  const imUsdBalance = await imUsdToken.balanceOf(dsaWallet0.address);
  console.log("imUSD balance: ", toEther(imUsdBalance));

  const imUsdVaultBalance = await imUsdVault.balanceOf(dsaWallet0.address);
  console.log("imUSD Vault balance: ", toEther(imUsdVaultBalance));

  // Should have something in the vault but no imUSD
  expect(await imUsdToken.balanceOf(dsaWallet0.address)).to.be.eq(0);
  expect(await imUsdVault.balanceOf(dsaWallet0.address)).to.be.gt(imUsdVaultBalanceBefore);
  expect(FromBalanceAfter).to.eq(FromBalanceBefore.sub(depositAmount));
};

export const executeAndAssertWithdraw = async (
  method: string,
  tokenTo: IERC20Minimal,
  withdrawAmount: BigNumber,
  dsaWallet0: Contract,
  wallet0: Wallet,
  args: any[]
) => {
  const tokenToBalanceBefore = await tokenTo.balanceOf(dsaWallet0.address);
  console.log("Balance before: ", toEther(tokenToBalanceBefore));

  const imUsdVaultBalanceBefore = await imUsdVault.balanceOf(dsaWallet0.address);
  console.log("imUSD Vault balance before: ", toEther(imUsdVaultBalanceBefore));

  const spells = [
    {
      connector: connectorName,
      method,
      args: [tokenTo.address, withdrawAmount, ...(args ? args : []), 0, 0]
    }
  ];

  const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), DEAD_ADDRESS);

  const imUsdVaultBalanceAfter = await imUsdVault.balanceOf(dsaWallet0.address);
  console.log("imUSD Vault balance after: ", toEther(imUsdVaultBalanceAfter));

  const tokenToBalanceAfter = await tokenTo.balanceOf(dsaWallet0.address);
  console.log("Balance after: ", toEther(tokenToBalanceAfter));

  expect(imUsdVaultBalanceAfter).to.be.eq(imUsdVaultBalanceBefore.sub(withdrawAmount));
  expect(tokenToBalanceAfter).to.gt(tokenToBalanceBefore);
};
