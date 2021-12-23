import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers, network } = hre;
const { provider, deployContract } = waffle;

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import type { Signer, Contract } from "ethers";

import { ConnectV2Lixir__factory, ILixirVault__factory } from "../../../typechain";

const FeeAmount = {
  LOW: 500,
  MEDIUM: 3000,
  HIGH: 10000,
};

const TICK_SPACINGS: Record<number, number> = {
  500: 10,
  3000: 60,
  10000: 200,
};

const USDC_WETH_VAULT = "0x453A9f40a24DbE3CdB4edC988aF9bfE0F5602b15"

let tokenIds: any[] = [];
let liquidities: any[] = [];
const abiCoder = ethers.utils.defaultAbiCoder;

describe("Lixir", function() {
  const connectorName = "Lixir-v1";

  let dsaWallet0: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;
  let vault: Contract;

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;
  before(async () => {
    await network.provider.send("evm_setAutomine", [false]);
    await network.provider.send("evm_setIntervalMining", [3000]);
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 13005785,
          },
        },
      ],
    });
    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(
      abis.core.connectorsV2,
      addresses.core.connectorsV2
    );

    vault = await ethers.getContractAt(
      ILixirVault__factory.abi,
      USDC_WETH_VAULT
    );

    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2Lixir__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2,
    });
    console.log("Connector address", connector.address);
  });

  it("Should have contracts deployed.", async function() {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function() {
    it("Should build DSA v2", async function() {
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH & USDC into DSA wallet", async function() {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10"),
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
        ethers.utils.parseEther("10")
      );

      await addLiquidity(
        "usdc",
        dsaWallet0.address,
        1000000 * 10**6 // USDC has 6 decimals
      );
    });
  });

  describe("Main", function() {
    it("Should deposit successfully", async function() {
      const usdcAmount = ethers.BigNumber.from(10**6).mul(4000); // ~1 ETH
      const ethAmount = ethers.utils.parseEther("1"); // 1 ETH

      const getIds = ["0", "0"];
      const setId = "0";

      const spells = [
        {
          connector: connectorName,
          method: "deposit",
          args: [ // get these right
            USDC_WETH_VAULT,
            usdcAmount,
            ethAmount,
            usdcAmount.sub(1000), // adding some slippage
            ethAmount.sub(1000), // adding some slippage
            dsaWallet0.address,
            1740297687, // high deadline
            getIds,
            setId,
          ],
        },
      ];

      const tx = await dsaWallet0
        .connect(wallet0)
        .cast(...encodeSpells(spells), wallet1.address);
      const receipt = await tx.wait();

      console.log(dsaWallet0)
      console.log(dsaWallet0.address)
      console.log(await masterSigner.provider?.getCode(USDC_WETH_VAULT))
      // idk why but any vault.function() calls are broken rn
      const meme = await vault.token0();
      
      console.log(meme);
      // console.log(await vault.balanceOf(wallet1.address));
      // const dsaLvtBalance = await vault.balanceOf(dsaWallet0.address);
      // console.log(dsaLvtBalance);
      // expect(dsaLvtBalance).gte(0);
    });

    // it("Should withdraw successfully", async function() {
    //   const getId = "0";
    //   const setIds = ["0", "0"];

    //   const data = await nftManager.positions(tokenIds[0]);
    //   let data1 = await nftManager.positions(tokenIds[1]);

    //   const spells = [
    //     {
    //       connector: connectorName,
    //       method: "withdraw",
    //       args: [tokenIds[0], data.liquidity, 0, 0, getId, setIds],
    //     },
    //     {
    //       connector: connectorName,
    //       method: "withdraw",
    //       args: [0, data1.liquidity, 0, 0, getId, setIds],
    //     },
    //   ];

    //   const tx = await dsaWallet0
    //     .connect(wallet0)
    //     .cast(...encodeSpells(spells), wallet1.address);
    //   const receipt = await tx.wait();

    //   data1 = await nftManager.positions(tokenIds[1]);
    //   expect(data1.liquidity.toNumber()).to.be.equals(0);
    // });
  });
});
