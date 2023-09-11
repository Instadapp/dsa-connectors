import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers } = hre;
const { provider, deployContract } = waffle;

import { Signer, Contract } from "ethers";
import { BigNumber } from "bignumber.js";

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { tokens, dsaMaxValue } from "../../../scripts/tests/mainnet/tokens";
import { abis } from "../../../scripts/constant/abis";
import { constants } from "../../../scripts/constant/constant";
import { ConnectV2CurveUSD__factory, IERC20Minimal__factory } from "../../../typechain";

// import ABI_Ctr from "./ABI.json"

describe("CRV USD", function () {
  const connectorName = "CRV_USD-TEST-A";
  const market = "0xc3d688B66703497DAA19211EEdff47f25384cdc3";
  const base = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
  const wst_whale = "0x78bB3aEC3d855431bd9289fD98dA13F9ebB7ef15";
  const wethWhale = "0x78bB3aEC3d855431bd9289fD98dA13F9ebB7ef15";

  const wethContract = new ethers.Contract(
    tokens.weth.address,
    IERC20Minimal__factory.abi,
    ethers.provider
  );
  const baseContract = new ethers.Contract(
    base,
    IERC20Minimal__factory.abi,
    ethers.provider
  );
  const linkContract = new ethers.Contract(
    tokens.wbtc.address,
    IERC20Minimal__factory.abi,
    ethers.provider
  );
  const crvUSD = new ethers.Contract(
    tokens.crvusd.address,
    IERC20Minimal__factory.abi,
    ethers.provider
  );
  const sfrxEth = new ethers.Contract(
    tokens.sfrxeth.address,
    IERC20Minimal__factory.abi,
    ethers.provider
  );

  let dsaWallet0: any;
  let dsaWallet1: any;
  let dsaWallet2: any;
  let dsaWallet3: any;
  let wallet: any;
  let dsa0Signer: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;
  let signer: any;
  let sfrxSigner: any;

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            //@ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            // blockNumber: 17811076
          }
        }
      ]
    });
    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2CurveUSD__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
    console.log("Connector address", connector.address);

    await hre.network.provider.send("hardhat_setBalance", [wst_whale, ethers.utils.parseEther("10").toHexString()]);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [wst_whale]
    });

    signer = await ethers.getSigner(wst_whale);
  });

  it("Should have contracts deployed.", async function () {
    expect(!!instaConnectorsV2.address).to.be.true;
    expect(!!connector.address).to.be.true;
    expect(!!(await masterSigner.getAddress())).to.be.true;
  });

  describe("DSA wallet setup", function () {
    it("Should build DSA v2", async function () {
      dsaWallet0 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet0.address).to.be.true;
      dsaWallet1 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet1.address).to.be.true;
      dsaWallet2 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet2.address).to.be.true;
      dsaWallet3 = await buildDSAv2(wallet0.address);
      expect(!!dsaWallet3.address).to.be.true;
      wallet = await ethers.getSigner(dsaWallet0.address);
      expect(!!dsaWallet1.address).to.be.true;
    });

    it("Deposit ETH into DSA wallet", async function () {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [wallet.address]
      });

      dsa0Signer = await ethers.getSigner(wallet.address);
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
      await wallet0.sendTransaction({
        to: dsaWallet1.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));
      await wallet0.sendTransaction({
        to: dsaWallet3.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

      let txRes = await sfrxEth.connect(signer).transfer(dsaWallet0.address, ethers.utils.parseEther("10000"));
      await txRes.wait();
      txRes = await sfrxEth.connect(signer).transfer(dsaWallet1.address, ethers.utils.parseEther("1000"));
      await txRes.wait();
      txRes = await sfrxEth.connect(signer).transfer(dsaWallet2.address, ethers.utils.parseEther("1000"));
      await txRes.wait();
    });
  });

  describe("Main", function () {
    //deposit asset
    it("Create Loan", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "createLoan",
          args: [tokens.sfrxeth.address, ethers.utils.parseEther('1').toString(), ethers.utils.parseEther('1000'), "10", "1", "0", "0"]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      await tx.wait();

      expect(await crvUSD.balanceOf(dsaWallet0.address)).to.be.eq(
        ethers.utils.parseEther("1000")
      );
    });

    it("add Collateral", async function () {
      const balanceBefore = await sfrxEth.balanceOf(dsaWallet0.address)
      const spells = [
        {
          connector: connectorName,
          method: "addCollateral",
          args: [tokens.sfrxeth.address, ethers.utils.parseEther('1').toString(), "1", 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      await tx.wait();

      expect(await sfrxEth.balanceOf(dsaWallet0.address)).to.be.eq(
        ethers.BigNumber.from(balanceBefore).sub(ethers.utils.parseEther('1'))
      );
    });

    it("remove Collateral", async function () {
      const balance = await sfrxEth.balanceOf(dsaWallet0.address)
      const spells = [
        {
          connector: connectorName,
          method: "removeCollateral",
          args: [tokens.sfrxeth.address, ethers.utils.parseEther('1').toString(), "1", 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      await tx.wait();

      expect(await sfrxEth.balanceOf(dsaWallet0.address)).to.be.eq(
        ethers.BigNumber.from(balance).add(ethers.utils.parseEther('1'))
      );
    });

    it("borrow more", async function () {
      const balance = await crvUSD.balanceOf(dsaWallet0.address)
      const spells = [
        {
          connector: connectorName,
          method: "borrowMore",
          args: [tokens.sfrxeth.address, ethers.utils.parseEther('50'), "1", 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      await tx.wait();

      expect(await crvUSD.balanceOf(dsaWallet0.address)).to.be.eq(
        ethers.BigNumber.from(balance).add(ethers.utils.parseEther('50'))
      );
    });

    it("addCollateralAndBorrowMore with maximum value", async function () {
      const balance = await crvUSD.balanceOf(dsaWallet0.address)
      const spells = [
        {
          connector: connectorName,
          method: "addCollateralAndBorrowMore",
          args: [tokens.sfrxeth.address, ethers.utils.parseEther('2'), dsaMaxValue, 1, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      await tx.wait();

      expect(await crvUSD.balanceOf(dsaWallet0.address)).to.be.gt(
        ethers.BigNumber.from(balance).add(ethers.utils.parseEther('100'))
      );
    });

    it("Revert when loan exists", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "createLoan",
          args: [tokens.sfrxeth.address, ethers.utils.parseEther('1').toString(), dsaMaxValue, 10, "1", "0", "0"]
        }
      ];
      await expect(dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address)).to.be.revertedWith('Loan already created');
    });


    it("create loan with maximum debt", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "createLoan",
          args: [tokens.sfrxeth.address, ethers.utils.parseEther('1').toString(), dsaMaxValue, 10, "1", "0", "0"]
        }
      ];

      const tx = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      await tx.wait();

      expect(await crvUSD.balanceOf(dsaWallet1.address)).to.be.gt(
        ethers.utils.parseEther("1000")
      );

      console.log("maximum debt amount: ", (await crvUSD.balanceOf(dsaWallet1.address)).toString() )
    });

    it("Repay loans", async function () {
      const balance = await crvUSD.balanceOf(dsaWallet1.address)
      const spells = [
        {
          connector: connectorName,
          method: "repay",
          args: [tokens.sfrxeth.address, ethers.utils.parseEther('100').toString(), "1", "0", "0"]
        }
      ];
      const tx = await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      expect(await crvUSD.balanceOf(dsaWallet1.address)).to.be.eq(
        ethers.BigNumber.from(balance).sub(ethers.utils.parseEther('100'))
      );
    });

    it("Repay loans with max value", async function () {
      const balance = await crvUSD.balanceOf(dsaWallet1.address)
      const spells = [
        {
          connector: connectorName,
          method: "repay",
          args: [tokens.sfrxeth.address, dsaMaxValue, "1", "0", "0"]
        }
      ];
      await dsaWallet1.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      expect(await crvUSD.balanceOf(dsaWallet1.address)).to.be.eq(0);
    });

    it("Create Loan with maximum collateral and maximum debt", async function () {
      const spells = [
        {
          connector: connectorName,
          method: "createLoan",
          args: [tokens.sfrxeth.address, dsaMaxValue, dsaMaxValue, 10, "1", "0", "0"]
        }
      ];

      const tx = await dsaWallet2.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      await tx.wait();

      expect(await crvUSD.balanceOf(dsaWallet2.address)).to.be.gt(
        ethers.utils.parseEther("1000").toString()
      );
      expect(await sfrxEth.balanceOf(dsaWallet2.address)).to.be.eq(
        '0'
      );
      console.log("maximum debt amount after maximum collateral: ", (await crvUSD.balanceOf(dsaWallet2.address)).toString() )
    });

    it("Create Loan with eth", async function () {
      const balance = await ethers.provider.getBalance(dsaWallet0.address)
      const spells = [
        {
          connector: connectorName,
          method: "createLoan",
          args: [tokens.eth.address, ethers.utils.parseEther('2').toString(), dsaMaxValue, 10, "0", "0", "0"]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      await tx.wait();

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.eq(
        ethers.BigNumber.from(balance).sub(ethers.utils.parseEther('2'))
      );
      console.log("maximum debt amount after create loan with 2 eth: ", (await crvUSD.balanceOf(dsaWallet0.address)).toString() )
    });

    it("add Collateral eth", async function () {
      const balance = await ethers.provider.getBalance(dsaWallet0.address)
      const spells = [
        {
          connector: connectorName,
          method: "addCollateral",
          args: [tokens.eth.address, ethers.utils.parseEther('3').toString(), 0, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      await tx.wait();

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.eq(
        ethers.BigNumber.from(balance).sub(ethers.utils.parseEther('3'))
      );
    });

    it("remove Collateral eth", async function () {
      const balance = await ethers.provider.getBalance(dsaWallet0.address)
      const spells = [
        {
          connector: connectorName,
          method: "removeCollateral",
          args: [tokens.eth.address, ethers.utils.parseEther('1').toString(), 0, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      await tx.wait();

      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.eq(
        ethers.BigNumber.from(balance).add(ethers.utils.parseEther('1'))
      );
    });

    it("borrow more", async function () {
      const balance = await crvUSD.balanceOf(dsaWallet0.address)
      const spells = [
        {
          connector: connectorName,
          method: "borrowMore",
          args: [tokens.eth.address, ethers.utils.parseEther('10'), 0, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      await tx.wait();

      expect(await crvUSD.balanceOf(dsaWallet0.address)).to.be.eq(
        ethers.BigNumber.from(balance).add(ethers.utils.parseEther('10'))
      );
    });

    it("borrow more", async function () {
      const balance = await crvUSD.balanceOf(dsaWallet0.address)
      const spells = [
        {
          connector: connectorName,
          method: "borrowMore",
          args: [tokens.eth.address, dsaMaxValue, 0, 0, 0]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      await tx.wait();
      expect(await crvUSD.balanceOf(dsaWallet0.address)).to.be.gt(
        ethers.BigNumber.from(balance).add(ethers.utils.parseEther('1000'))
      );
    });


    it("Repay loans", async function () {
      const balance = await crvUSD.balanceOf(dsaWallet0.address)
      const spells = [
        {
          connector: connectorName,
          method: "repay",
          args: [tokens.eth.address, ethers.utils.parseEther('100').toString(), "0", "0", "0"]
        }
      ];
      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      expect(await crvUSD.balanceOf(dsaWallet0.address)).to.be.eq(
        ethers.BigNumber.from(balance).sub(ethers.utils.parseEther('100'))
      );
    });

    it("Repay loans with max value", async function () {
      const balance = await crvUSD.balanceOf(dsaWallet0.address)
      const spells = [
        {
          connector: connectorName,
          method: "repay",
          args: [tokens.eth.address, dsaMaxValue, "0", "0", "0"]
        }
      ];
      await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      console.log("crv balance after repay with max value: ",await crvUSD.balanceOf(dsaWallet0.address))
    });

  });
});
