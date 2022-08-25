import { expect } from "chai";
import hre from "hardhat";
import { abis } from "../../../scripts/constant/abis";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { ConnectV2EulerImport__factory, IERC20__factory } from "../../../typechain";
import { parseEther, parseUnits } from "@ethersproject/units";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
const { ethers } = hre;
import type { Signer, Contract } from "ethers";
import { BigNumber } from "bignumber.js";
import { Address } from "@project-serum/anchor";

const DAI = '0x6b175474e89094c44da98b954eedeac495271d0f'
const Dai = parseUnits('50', 18)

const WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
const ACC_WETH = '0x05547D4e1A2191B91510Ea7fA8555a2788C70030'
const Weth = parseUnits('50', 18)

const ETH = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'

const token_weth = new ethers.Contract(
  WETH,
  [{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"guy","type":"address"},{"name":"wad","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"src","type":"address"},{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"wad","type":"uint256"}],"name":"withdraw","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"deposit","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"address"},{"name":"","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":true,"name":"guy","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":true,"name":"dst","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"dst","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Withdrawal","type":"event"}],
  // IERC20__factory.abi,
  ethers.provider,
)

const token_dai = new ethers.Contract(
  DAI,
  IERC20__factory.abi,
  ethers.provider,
)

const eTokensABI = [
  "function approve(address, uint256) public",
  "function balanceOf(address account) public view returns (uint256)",
  "function allowance(address, address) public returns (uint256)",
  "function deposit(uint256,uint256) public",
  "function balanceOfUnderlying(address) public view returns (uint256)",
  "function mint(uint256,uint256) public",
  "function approveSubAccount(uint256, address, uint256) public"
];

const dTokensABI = [
  "function balanceOf(address account) public view returns (uint256)",
  "function borrow(uint256,uint256) public"
];

const marketsABI = [
  "function enterMarket(uint256,address) public",
  "function underlyingToEToken(address) public view returns (address)",
	"function underlyingToDToken(address) public view returns (address)"
]

const eWethAddress = '0x1b808F49ADD4b8C6b5117d9681cF7312Fcf0dC1D';
const eWethContract = new ethers.Contract(eWethAddress, eTokensABI);

const dWethAddress = '0x62e28f054efc24b26A794F5C1249B6349454352C'
const dWethContract = new ethers.Contract(dWethAddress, dTokensABI);

const dDaiAddress = '0x6085Bc95F506c326DCBCD7A6dd6c79FBc18d4686';
const dDaiContract = new ethers.Contract(dDaiAddress, dTokensABI);

const euler_mainnet = '0x27182842E098f60e3D576794A5bFFb0777E025d3'
const euler_markets = '0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3'
const marketsContract = new ethers.Contract(euler_markets, marketsABI);


describe("Euler", function () {
    const connectorName = "EULER-IMPORT-TEST-A";
    let connector: any;
  
    let wallet0: Signer, wallet1:Signer;
    let dsaWallet0: any;
    let instaConnectorsV2: Contract;
    let masterSigner: Signer;
    let walletAddr: Address;
    let subAcc1: Address;
    let subAcc2DSA: Address;
  
    before(async () => {
      await hre.network.provider.request({
        method: "hardhat_reset",
        params: [
          {
            forking: {
              // @ts-ignore
              jsonRpcUrl: hre.config.networks.hardhat.forking.url,
              blockNumber: 15379000,
            },
          },
        ],
      });
      [wallet0, wallet1] = await ethers.getSigners();

      await hre.network.provider.send("hardhat_setBalance", [ACC_WETH, ethers.utils.parseEther("10").toHexString()]);

      await hre.network.provider.request({
          method: "hardhat_impersonateAccount",
          params: [ACC_WETH]
      });

      const signer_weth = await ethers.getSigner(ACC_WETH)
      await token_weth.connect(signer_weth).transfer(wallet0.getAddress(), ethers.utils.parseEther("8"));
      console.log("WETH transferred to wallet0");

      await hre.network.provider.request({
          method: 'hardhat_stopImpersonatingAccount',
          params: [ACC_WETH],
      })

      masterSigner = await getMasterSigner();
      instaConnectorsV2 = await ethers.getContractAt(
        abis.core.connectorsV2,
        addresses.core.connectorsV2
      );
      connector = await deployAndEnableConnector({
        connectorName,
        contractArtifact: ConnectV2EulerImport__factory,
        signer: masterSigner,
        connectors: instaConnectorsV2,
      });
      console.log("Connector address", connector.address);
      walletAddr = (await wallet0.getAddress()).toString()
      console.log("walletAddr: ", walletAddr)
      subAcc1 = ethers.BigNumber.from(walletAddr).xor(1).toHexString()
      console.log("subAcc1: ", subAcc1)
    });
  
    it("should have contracts deployed", async () => {
      expect(!!instaConnectorsV2.address).to.be.true;
      expect(!!connector.address).to.be.true;
      expect(!!(await masterSigner.getAddress())).to.be.true;
    });
  
    describe("DSA wallet setup", function () {
      it("Should build DSA v2", async function () {
        dsaWallet0 = await buildDSAv2(wallet0.getAddress());
        expect(!!dsaWallet0.address).to.be.true;
        
        subAcc2DSA = ethers.BigNumber.from(dsaWallet0.address).xor(2).toHexString()
        console.log("subAcc2DSA: ", subAcc2DSA)
      });
  
      it("Deposit ETH into DSA wallet", async function () {
        await wallet0.sendTransaction({
          to: dsaWallet0.address,
          value: parseEther("10"),
        });
        expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(
          parseEther("10")
        );
      });

      describe("Create Euler position in SUBACCOUNT 0", async () => {
        it("Should create Euler position of WETH(collateral) and DAI(debt)", async () => {
          // approve WETH to euler
          await token_weth.connect(wallet0).approve(euler_mainnet, Weth);
          console.log("Approved WETH");
    
          // deposit WETH in euler
          await eWethContract.connect(wallet0).deposit("0", parseEther("2"));
          expect(await eWethContract.connect(wallet0).balanceOfUnderlying(walletAddr)).to.be.gte(parseEther("1.9"));
          console.log("Supplied WETH on Euler");

          // enter WETH market
          await marketsContract.connect(wallet0).enterMarket("0", WETH);
          console.log("Entered market for WETH");
    
          // borrow DAI from Euler
          await dDaiContract.connect(wallet0).borrow("0", Dai);
          console.log("Borrowed DAI from Euler");
        });
    
        it("Should check created position of user", async () => {
          expect(await token_dai.connect(wallet0).balanceOf(walletAddr)).to.be.gte(
            parseUnits('50', 18)
          );
        });
      });

      describe("Create Euler self-position in SUBACCOUNT 1", async () => {
        it("Should create Euler self-position of WETH(collateral) and WETH(debt)", async () => {
          // approve WETH to euler
          await token_weth.connect(wallet0).approve(euler_mainnet, Weth);
          console.log("Approved WETH");
    
          // deposit WETH in euler
          await eWethContract.connect(wallet0).deposit("1", parseEther("2"));
          expect(await eWethContract.connect(wallet0).balanceOfUnderlying(subAcc1)).to.be.gte(parseEther("1.9"));
          console.log("Supplied WETH on Euler");

          // enter WETH market
          await marketsContract.connect(wallet0).enterMarket("1", WETH);
          console.log("Entered market for WETH");
    
          // mint WETH from Euler
          await eWethContract.connect(wallet0).mint("1", parseEther("1"));
          expect(await eWethContract.connect(wallet0).balanceOfUnderlying(subAcc1)).to.be.gte(parseEther("2.9"));
          console.log("Minted WETH from Euler");
        });

        it("Should check created position of user", async () => {
          expect(await eWethContract.connect(wallet0).balanceOfUnderlying(subAcc1)).to.be.gte(parseEther("2.9"));
        });
      });
  
    describe("Euler position migration", async () => {
      it("Approve sub-account0 eTokens for import to DSA sub-account 0", async () => {
        let balance = await eWethContract.connect(wallet0).balanceOf(walletAddr)
        await eWethContract.connect(wallet0).approve(dsaWallet0.address, balance);
      });

      it("Approve sub-account1 eTokens for import to DSA sub-account 2", async () => {
        let balance = await eWethContract.connect(wallet0).balanceOf(subAcc1)
        await eWethContract.connect(wallet0).approveSubAccount("1", dsaWallet0.address, balance);
      });

      it("Should migrate euler position of sub-account 0 to DSA sub-account 0", async () => {
        const spells = [
          {
            connector: "EULER-IMPORT-TEST-A",
            method: "importEuler",
            args: [
              walletAddr,
              "0",
              "0",
              [[ETH],[DAI],["true"]]
            ]
          },
        ];
        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.getAddress());
        const receipt = await tx.wait();
      });

      it("Should check migration", async () => {
        expect(await eWethContract.connect(wallet0).balanceOfUnderlying(dsaWallet0.address)).to.be.gte(parseEther("2"));
        expect(await dDaiContract.connect(wallet0).balanceOf(dsaWallet0.address)).to.be.gte(parseEther("50"));
      });

      it("Should migrate euler position of sub-account 1 to DSA sub-account 2", async () => {
        const spells = [
          {
            connector: "EULER-IMPORT-TEST-A",
            method: "importEuler",
            args: [
              walletAddr,
              "1",
              "2",
              [[ETH],[ETH],["true"]]
            ]
          },
        ];
        const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.getAddress());
        const receipt = await tx.wait();
      });

      it("Should check migration", async () => {
        expect(await eWethContract.connect(wallet0).balanceOfUnderlying(subAcc2DSA)).to.be.gte(parseEther("3"));
        expect(await dWethContract.connect(wallet0).balanceOf(subAcc2DSA)).to.be.gte(parseEther("1"));
      });
    })
});
})
