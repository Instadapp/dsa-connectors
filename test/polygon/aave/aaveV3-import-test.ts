import { expect, should } from "chai";
import hre, { ethers, waffle } from "hardhat";
import type { Signer, Contract } from "ethers";
import { ecsign, ecrecover, pubToAddress } from "ethereumjs-util";
import { keccak256 } from "@ethersproject/keccak256";
import { toUtf8Bytes } from "@ethersproject/strings";
import { defaultAbiCoder } from "@ethersproject/abi";
import { BigNumber } from "bignumber.js";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { addresses } from "../../../scripts/tests/polygon/addresses";
import { tokens } from "../../../scripts/tests/polygon/tokens";
import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { abis } from "../../../scripts/constant/abis";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import encodeFlashcastData from "../../../scripts/tests/encodeFlashcastData";
import { ConnectV2AaveV3ImportPermitPolygon__factory } from "../../../typechain";
import { parse } from "path/posix";
import { aave } from "dsa-connect/dist/abi/connectors/v1";
const { provider } = waffle;

const aDaiAddress = "0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE";
const aEthAddress = "0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8";
const aaveAddress = "0x794a61358D6845594F94dc1DB02A252b5b4814aD";
const daiAddress = tokens.dai.address;
const mnemonic = "test test test test test test test test test test test junk";

describe("Import Aave", async function () {
  const connectorName = "AAVE-V3-IMPORT-PERMIT-X";

  const aEthAbi = [
    {
      inputs: [{ internalType: "address", name: "user", type: "address" }],
      name: "balanceOf",
      outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
      stateMutability: "view",
      type: "function"
    },
    {
      inputs: [
        { internalType: "address", name: "caller", type: "address" },
        { internalType: "address", name: "onBehalfOf", type: "address" },
        { internalType: "uint256", name: "amount", type: "uint256" },
        { internalType: "uint256", name: "index", type: "uint256" }
      ],
      name: "mint",
      outputs: [{ internalType: "bool", name: "", type: "bool" }],
      stateMutability: "nonpayable",
      type: "function"
    },
    {
      inputs: [{ internalType: "address", name: "owner", type: "address" }],
      name: "nonces",
      outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
      stateMutability: "view",
      type: "function"
    }
  ];

  const aDaiAbi = [
    {
      inputs: [{ internalType: "address", name: "user", type: "address" }],
      name: "balanceOf",
      outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
      stateMutability: "view",
      type: "function"
    },
    {
      inputs: [
        { internalType: "address", name: "caller", type: "address" },
        { internalType: "address", name: "onBehalfOf", type: "address" },
        { internalType: "uint256", name: "amount", type: "uint256" },
        { internalType: "uint256", name: "index", type: "uint256" }
      ],
      name: "mint",
      outputs: [{ internalType: "bool", name: "", type: "bool" }],
      stateMutability: "nonpayable",
      type: "function"
    },
    {
      inputs: [{ internalType: "address", name: "owner", type: "address" }],
      name: "nonces",
      outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
      stateMutability: "view",
      type: "function"
    }
  ];

  const aaveAbi = [
    {
      inputs: [
        {
          internalType: "address",
          name: "asset",
          type: "address"
        },
        {
          internalType: "uint256",
          name: "amount",
          type: "uint256"
        },
        {
          internalType: "uint256",
          name: "interestRateMode",
          type: "uint256"
        },
        {
          internalType: "uint16",
          name: "referralCode",
          type: "uint16"
        },
        {
          internalType: "address",
          name: "onBehalfOf",
          type: "address"
        }
      ],
      name: "borrow",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function"
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "asset",
          type: "address"
        },
        {
          internalType: "uint256",
          name: "amount",
          type: "uint256"
        },
        {
          internalType: "address",
          name: "onBehalfOf",
          type: "address"
        },
        {
          internalType: "uint16",
          name: "referralCode",
          type: "uint16"
        }
      ],
      name: "deposit",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function"
    },
    {
      inputs: [
        {
          internalType: "address",
          name: "asset",
          type: "address"
        },
        {
          internalType: "uint256",
          name: "amount",
          type: "uint256"
        },
        {
          internalType: "address",
          name: "onBehalfOf",
          type: "address"
        },
        {
          internalType: "uint16",
          name: "referralCode",
          type: "uint16"
        }
      ],
      name: "supply",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function"
    }
  ];

  const daiAbi = abis.basic.erc20;

  let aEth: Contract, aDai: Contract, Dai: any;
  let dsaWallet0: any;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: any;

  const wallet = ethers.Wallet.fromMnemonic(mnemonic);
  console.log(wallet.address);

  before(async () => {
    // await hre.network.provider.request({
    //   method: "hardhat_reset",
    //   params: [
    //     {
    //       forking: {
    //         //@ts-ignore
    //         jsonRpcUrl: hre.config.networks.hardhat.forking.url,
    //         blockNumber: await ethers.provider.getBlockNumber()
    //       }
    //     }
    //   ]
    // });
    masterSigner = await getMasterSigner();
    console.log(await masterSigner.getAddress());

    await hre.network.provider.send("hardhat_setBalance", [
      wallet.address,
      ethers.utils.parseEther("10").toHexString()
    ]);

    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2AaveV3ImportPermitPolygon__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });

    //check
    // const signerAddr = "0xDA9dfA130Df4dE4673b89022EE50ff26f6EA73Cf";
    // await hre.network.provider.request({
    //   method: "hardhat_impersonateAccount",
    //   params: [signerAddr]
    // });
    // let sig = await ethers.getSigner(signerAddr);

    console.log("Connector address", connector.address);
    aEth = new ethers.Contract(aEthAddress, aEthAbi);
    aDai = new ethers.Contract(aDaiAddress, aDaiAbi);
    Dai = new ethers.Contract(daiAddress, daiAbi);
    const aave = new ethers.Contract(aaveAddress, aaveAbi);

    //deposit ether to aave: ETH-A
    await aave.connect(wallet).deposit(aEthAddress, parseEther("9"), wallet.address, 3228);

    //borrow
    await aave.connect(wallet).borrow(aDaiAddress, parseUnits("100"), 1, 3228, wallet.address);

    // //building dsaWallet
    dsaWallet0 = await buildDSAv2(wallet.address);
    console.log(dsaWallet0.address);
    await hre.network.provider.send("hardhat_setBalance", [
      wallet.address,
      ethers.utils.parseEther("10").toHexString()
    ]);
    console.log("bro");

    // deposit ETH to dsa wallet
    await wallet.sendTransaction({
      to: dsaWallet0.address,
      value: ethers.utils.parseEther("10")
    });
    console.log(await ethers.provider.getBalance(dsaWallet0.address)); //should be 10
  });

  describe("Deployment", async () => {
    it("Should set correct name", async () => {
      expect(await connector.name()).to.eq("Aave-v3-import-permit-v1");
    });
  });

  describe("check user AAVE position", async () => {
    it("Should check position of user", async () => {
      const exchangeRate = 0.9289;
      expect(new BigNumber(await aEth.connect(wallet).balanceOf(wallet.address)).dividedBy(1e8).toFixed(0)).to.eq(
        new BigNumber(9).dividedBy(exchangeRate).toFixed(0)
      );
      expect(await Dai.connect(wallet).balanceOf(wallet.address)).to.eq("100000000000000000000");
    });
  });

  describe("Aave position migration", async () => {
    it("Should migrate Aave position", async () => {
      const name = "Aave ETH";
      const chainId = 137;
      const DOMAIN_SEPARATOR = keccak256(
        defaultAbiCoder.encode(
          ["bytes32", "bytes32", "bytes32", "uint256", "address"],
          [
            keccak256(
              toUtf8Bytes("EIP712Domain(string name, string version, uint256 chainId, address verifyingContract)")
            ),
            keccak256(toUtf8Bytes(name)),
            keccak256(toUtf8Bytes("1")),
            chainId,
            aEth.address
          ]
        )
      );
      const PERMIT_TYPEHASH = "0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9";
      let nonces = await aEth.connect(wallet).nonces(wallet.address);
      let nonce = nonces.toNumber();
      const amount = await aEth.connect(wallet).balanceOf(wallet.address);
      const expiry = Date.now() + 20 * 60;
      const digest = keccak256(
        ethers.utils.solidityPack(
          ["bytes1", "bytes1", "bytes32", "bytes32"],
          [
            "0x19",
            "0x01",
            DOMAIN_SEPARATOR,
            keccak256(
              defaultAbiCoder.encode(
                ["bytes32", "address", "address", "uint256", "uint256", "uint256"],
                [PERMIT_TYPEHASH, wallet.address, connector.address, amount, nonce, expiry]
              )
            )
          ]
        )
      );
      const { v, r, s } = ecsign(Buffer.from(digest.slice(2), "hex"), Buffer.from(wallet.privateKey.slice(2), "hex"));

      const amount0 = new BigNumber("100000007061117456728");
      const amountB = new BigNumber(amount0.toString()).multipliedBy(9).dividedBy(1e4);
      const amountWithFee = amount0.plus(amountB);

      const flashSpells = [
        {
          connector: "AAVE-V3-IMPORT-PERMIT-X",
          method: "importAave",
          args: [
            wallet.address,
            {
              supplyTokens: ["ETH-A"],
              borrowTokens: ["DAI-A"],
              convertStable: false,
              flashLoanFees: [amount.toFixed(0)]
            },
            { v: [v], r: [r], s: [s], expiry: [expiry] }
          ]
        },
        {
          connector: "INSTAPOOL-C",
          method: "flashPayBack",
          args: [daiAddress, amountWithFee.toFixed(0), 0, 0]
        }
      ];

      const spells = [
        {
          connector: "INSTAPOOL-C",
          method: "flashBorrowAndCast",
          args: [daiAddress, amount0.toString(), 0, encodeFlashcastData(flashSpells), "0x"]
        }
      ];
      const tx = await dsaWallet0.connect(wallet).cast(...encodeSpells(spells), wallet.address);
      const receipt = await tx.wait();
    });

    it("Should check DSA COMPOUND position", async () => {
      const ethExchangeRate = 0.9289;
      expect(new BigNumber(await aEth.connect(wallet).balanceOf(dsaWallet0.address)).dividedBy(1e8).toFixed(0)).to.eq(
        new BigNumber(9).dividedBy(ethExchangeRate).toFixed(0)
      );
    });
  });
});
