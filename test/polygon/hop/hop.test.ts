import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers } = hre;
const { provider } = waffle;

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";
import { addresses } from "../../../scripts/tests/polygon/addresses";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2HopPolygon__factory } from "../../../typechain";
import { Signer, Contract } from "ethers";
import BigNumber from "bignumber.js";

describe("Hop Connector", function () {
  const connectorName = "HOP-A";

  let dsaWallet0: Contract;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;
  let latestBlock: any;

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;

  const saddleSwapABI = [
    {
      inputs: [{ internalType: "address", name: "tokenAddress", type: "address" }],
      name: "getTokenIndex",
      outputs: [{ internalType: "uint8", name: "", type: "uint8" }],
      stateMutability: "view",
      type: "function"
    },
    {
      inputs: [
        { internalType: "uint8", name: "tokenIndexFrom", type: "uint8" },
        { internalType: "uint8", name: "tokenIndexTo", type: "uint8" },
        { internalType: "uint256", name: "dx", type: "uint256" }
      ],
      name: "calculateSwap",
      outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
      stateMutability: "view",
      type: "function"
    }
  ];

  const l2BridgeABI = [
    {
      anonymous: false,
      inputs: [
        { indexed: true, internalType: "bytes32", name: "transferId", type: "bytes32" },
        { indexed: true, internalType: "uint256", name: "chainId", type: "uint256" },
        { indexed: true, internalType: "address", name: "recipient", type: "address" },
        { indexed: false, internalType: "uint256", name: "amount", type: "uint256" },
        { indexed: false, internalType: "bytes32", name: "transferNonce", type: "bytes32" },
        { indexed: false, internalType: "uint256", name: "bonderFee", type: "uint256" },
        { indexed: false, internalType: "uint256", name: "index", type: "uint256" },
        { indexed: false, internalType: "uint256", name: "amountOutMin", type: "uint256" },
        { indexed: false, internalType: "uint256", name: "deadline", type: "uint256" }
      ],
      name: "TransferSent",
      type: "event"
    }
  ];

  const DAI_ADDR = "0x8f3cf7ad23cd3cadbd9735aff958023239c6a063";
  const hDai = "0xb8901acB165ed027E32754E0FFe830802919727f";
  const l2AmmWrapper = "0x28529fec439cfF6d7D1D5917e956dEE62Cd3BE5c";
  const l2Bridge = "0xEcf268Be00308980B5b3fcd0975D47C4C8e1382a";
  const saddleSwap = "0x25FB92E505F752F730cAD0Bd4fa17ecE4A384266";
  const saddleSwapInstance = new ethers.Contract(saddleSwap, saddleSwapABI);

  const token = new ethers.Contract(DAI_ADDR, abis.basic.erc20);
  const l2BridgeInstance = new ethers.Contract(l2Bridge, l2BridgeABI);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 27054896
          }
        }
      ]
    });

    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2HopPolygon__factory,
      signer: masterSigner,
      connectors: instaConnectorsV2
    });
    console.log("Connector address", connector.address);
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
    });

    it("Deposit MATIC & DAI into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

      await addLiquidity("dai", dsaWallet0.address, ethers.utils.parseEther("10000"));
    });
  });

  describe("Main", function () {
    it("should migrate from L2 to L1", async function () {
      const amount = ethers.utils.parseEther("10");
      const bonderFee = new BigNumber(100 * 1e9)
        .multipliedBy(150000)
        .multipliedBy(1.5)
        .plus(new BigNumber(amount.toString()).multipliedBy(0.18));
      const deadline = Date.now() + 604800;
      const getId = "0";

      await token.connect(wallet0).approve(l2AmmWrapper, amount.toString());

      const hDaiIdx = await saddleSwapInstance.connect(wallet0).getTokenIndex(hDai);
      const daiIdx = await saddleSwapInstance.connect(wallet0).getTokenIndex(DAI_ADDR);

      let amountOutMin = await saddleSwapInstance.connect(wallet0).calculateSwap(daiIdx, hDaiIdx, amount.toString());
      amountOutMin = new BigNumber(amountOutMin.toString()).multipliedBy(0.99);

      const params: any = [
        DAI_ADDR,
        l2AmmWrapper,
        wallet0.address,
        1,
        amount.toString(),
        bonderFee.toString(),
        amountOutMin.toFixed(0),
        deadline,
        "0",
        "0"
      ];

      const spells = [
        {
          connector: connectorName,
          method: "bridge",
          args: [params, getId]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      let receipt = await tx.wait();
      latestBlock = receipt.blockNumber;
    });

    it("Should fetch transferId from TransferSent Event", async function () {
      const filter = l2BridgeInstance.connect(wallet0).filters.TransferSent();
      const events = await l2BridgeInstance.connect(wallet0).queryFilter(filter, 27054896, latestBlock);

      const transferSentEvent: any = events[0].args;

      expect(transferSentEvent[2].toLowerCase()).to.be.equals(wallet0.address.toLowerCase());
      console.log("TransferId", transferSentEvent[0]);
    });

    it("should migrate from L2 to L2", async function () {
      const amount = ethers.utils.parseEther("10");

      const hDaiIdx = await saddleSwapInstance.connect(wallet0).getTokenIndex(hDai);
      const daiIdx = await saddleSwapInstance.connect(wallet0).getTokenIndex(DAI_ADDR);

      let destinationAmountOutMin = await saddleSwapInstance
        .connect(wallet0)
        .calculateSwap(hDaiIdx, daiIdx, amount.toString());
      destinationAmountOutMin = new BigNumber(destinationAmountOutMin.toString()).multipliedBy(0.99);

      let amountOutMin = await saddleSwapInstance.connect(wallet0).calculateSwap(daiIdx, hDaiIdx, amount.toString());
      amountOutMin = new BigNumber(amountOutMin.toString()).multipliedBy(0.99);

      const bonderFee = new BigNumber(1e9)
        .multipliedBy(150000)
        .multipliedBy(1.5)
        .plus(new BigNumber(amount.toString()).multipliedBy(0.18));
      const deadline = Date.now() + 604800;
      const getId = "0";

      await token.connect(wallet0).approve(l2AmmWrapper, amount.toString());

      const params: any = [
        DAI_ADDR,
        l2AmmWrapper,
        wallet0.address,
        10,
        amount.toString(),
        bonderFee.toString(),
        amountOutMin.toFixed(0),
        deadline,
        destinationAmountOutMin.toFixed(0),
        deadline
      ];

      const spells = [
        {
          connector: connectorName,
          method: "bridge",
          args: [params, getId]
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet1.address);
      let receipt = await tx.wait();
      latestBlock = receipt.blockNumber;
    });

    it("Should fetch transferId from TransferSent Event", async function () {
      const filter = l2BridgeInstance.connect(wallet0).filters.TransferSent();
      const events = await l2BridgeInstance.connect(wallet0).queryFilter(filter, 27054896, latestBlock);

      const transferSentEvent: any = events[1].args;

      expect(transferSentEvent[2].toLowerCase()).to.be.equals(wallet0.address.toLowerCase());
      console.log("TransferId", transferSentEvent[0]);
    });
  });
});
