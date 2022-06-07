import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers } = hre;
const { provider } = waffle;
import axios from "axios";
import fetch from "node-fetch";

import { deployAndEnableConnector } from "../../../scripts/tests/deployAndEnableConnector";
import { buildDSAv2 } from "../../../scripts/tests/buildDSAv2";
import { encodeSpells } from "../../../scripts/tests/encodeSpells";
import { getMasterSigner } from "../../../scripts/tests/getMasterSigner";
import { addLiquidity } from "../../../scripts/tests/addLiquidity";
import { addresses } from "../../../scripts/tests/mainnet/addresses";
import { abis } from "../../../scripts/constant/abis";
import { ConnectV2Socket__factory } from "../../../typechain";
import { Signer, Contract } from "ethers";

describe("Socket Connector", function () {
  const connectorName = "SOCKET-MAINNET-X";

  let dsaWallet0: Contract;
  let masterSigner: Signer;
  let instaConnectorsV2: Contract;
  let connector: Contract;
  let build_tx_data, quote, allowance, sender

  const fromChainId = "1"
  const toChainId = "137"
  const recipient = "0xD625c7458Da1a0758dA8d3AC7f2c10180Bf0E506"
  const _getId = "0";

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;
  const API_KEY = '645b2c8c-5825-4930-baf3-d9b997fcd88c';

  const DAI_ADDR_ETH = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const DAI_ADDR_POLYGON = "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063";

  const token = new ethers.Contract(DAI_ADDR_ETH, abis.basic.erc20);

  before(async () => {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            // @ts-ignore
            jsonRpcUrl: hre.config.networks.hardhat.forking.url,
            blockNumber: 14854895
          }
        }
      ]
    });

    masterSigner = await getMasterSigner();
    instaConnectorsV2 = await ethers.getContractAt(abis.core.connectorsV2, addresses.core.connectorsV2);
    connector = await deployAndEnableConnector({
      connectorName,
      contractArtifact: ConnectV2Socket__factory,
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
      console.log("dsaWallet0: ", dsaWallet0.address)
      expect(!!dsaWallet0.address).to.be.true;
    });

    it("Deposit ETH & DAI into DSA wallet", async function () {
      await wallet0.sendTransaction({
        to: dsaWallet0.address,
        value: ethers.utils.parseEther("10")
      });
      expect(await ethers.provider.getBalance(dsaWallet0.address)).to.be.gte(ethers.utils.parseEther("10"));

      await addLiquidity("dai", dsaWallet0.address, ethers.utils.parseEther("10000"));
    });
  });

  //##1
  async function getQuote(
    fromChainId: any,
    fromTokenAddress: any,
    toChainId: any,
    toTokenAddress: any,
    fromAmount: any,
    userAddress: any,
    recipient: any,
    uniqueRoutesPerBridge: any)
  {
    const response = await fetch(`https://api.socket.tech/v2/quote?fromChainId=${fromChainId}&fromTokenAddress=${fromTokenAddress}&toChainId=${toChainId}&toTokenAddress=${toTokenAddress}&fromAmount=${fromAmount}&userAddress=${userAddress}&recipient=${recipient}&uniqueRoutesPerBridge=${uniqueRoutesPerBridge}&includeDexes=&excludeDexes=&includeBridges=&excludeBridges=&sort=output&singleTxOnly=true&isContractCall=true`, {
        method: 'GET',
        headers: {
            'API-KEY': API_KEY,
            'Accept': 'application/json',
            'Content-Type': 'application/json',
    }});
    quote = await response.json();
    return(quote)
  }

  //##2
  async function getRouteTransactionData(route: any) {
    const response = await fetch('https://api.socket.tech/v2/build-tx', {
            method: 'POST',
            headers: {
                'API-KEY': API_KEY,
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ "route": route })
            })
    build_tx_data = await response.json();
    return(build_tx_data)
  }

  //##3
  async function checkAllowance(
    chainId: any,
    owner: any,
    allowanceTarget: any,
    tokenAddress: any)
  {
      const response = await fetch(`https://api.socket.tech/v2/approval/check-allowance?chainID=${chainId}&owner=${owner}&allowanceTarget=${allowanceTarget}&tokenAddress=${tokenAddress}`, {
      method: 'GET',
      headers: {
          'API-KEY': API_KEY,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
      }
      });
      const allowance = await response.json();
      return allowance;
  }

  //##4
  async function getApprovalTransactionData(
    chainId: any,
    owner: any,
    allowanceTarget: any,
    tokenAddress: any,
    amount: any)
  {
    const response = await fetch(`https://api.socket.tech/v2/approval/build-tx?chainID=${chainId}&owner=${owner}&allowanceTarget=${allowanceTarget}&tokenAddress=${tokenAddress}&amount=${amount}`, {
          method: 'GET',
          headers: {
              'API-KEY': API_KEY,
              'Accept': 'application/json',
              'Content-Type': 'application/json'
          }
      });
      const approvalTransactionData = await response.json();
      sender = await approvalTransactionData.result?.from;
      return approvalTransactionData;
  }

  //##5
  async function getBridgeStatus(
    transactionHash: any, 
    fromChainId: any, 
    toChainId: any)
  {
    const response = await fetch(`https://api.socket.tech/v2/bridge-status?transactionHash=${transactionHash}&fromChainId=${fromChainId}&toChainId=${toChainId}`, {
        method: 'GET',
        headers: {
            'API-KEY': API_KEY,
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        }
    });
    const status = await response.json();
    return status;
}

  describe("Main", function () {
    it("should send DAI from ETH to Polygon", async function () {
      const quote = await getQuote(fromChainId, DAI_ADDR_ETH, toChainId, DAI_ADDR_POLYGON, "10000000000000000000", dsaWallet0.address, recipient, "true");
      console.log("quote: ", quote)
      const route = quote.result.routes[0];
      console.log("route: ", quote.result.routes[0])
      const apiReturnData = await getRouteTransactionData(route);
      console.log("build-tx: ", apiReturnData)
      const { allowanceTarget, minimumApprovalAmount } = apiReturnData.result.approvalData;

      const dsa_signer = await ethers.getSigner(dsaWallet0.address)
      const _params: any = [apiReturnData.result.txTarget, apiReturnData.result?.txData, DAI_ADDR_ETH, allowanceTarget, "10000000000000000000"];

      const spells = [
        {
          connector: connectorName,
          method: "bridge",
          args: [_params, _getId]
        }
      ];

      const txn = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
      let receipt = await txn.wait();
      // console.log("receipt: ", receipt);

      if (allowanceTarget !== null) {
        const allowanceCheckStatus = await checkAllowance(fromChainId, dsaWallet0.address, allowanceTarget, DAI_ADDR_ETH)
        console.log("allowanceCheckStatus: ", allowanceCheckStatus);
        const allowanceValue = allowanceCheckStatus.result?.value;
        // console.log("allowanceValue: ", allowanceValue);

        if (minimumApprovalAmount > allowanceValue) {
            const approvalTransactionData = await getApprovalTransactionData(fromChainId, dsaWallet0.address, allowanceTarget, DAI_ADDR_ETH, minimumApprovalAmount);
            console.log("approvalTransactionData: ", approvalTransactionData);
          };
    }

    const gasPrice = await dsa_signer.getGasPrice();
    console.log("gasPrice: ", gasPrice)

    // const gasEstimate = await provider.estimateGas({
    //     from: dsaWallet0.address,
    //     to: apiReturnData.result.txTarget,
    //     value: apiReturnData.result.value,
    //     data: apiReturnData.result.txData,
    //     gasPrice: gasPrice
    // });
    // console.log("gasEstimate: ", gasEstimate)

    const tx = await dsa_signer.sendTransaction({
        from: dsaWallet0.address,
        to: apiReturnData.result.txTarget,
        data: apiReturnData.result.txData,
        value: apiReturnData.result.value,
        gasPrice: gasPrice
        // gasLimit: gasEstimate
    });

    const receiptn = await tx.wait();
    const txHash = receiptn.transactionHash;
    console.log('Bridging Transaction : ', receipt.transactionHash);

    // Checks status of transaction every 20 secs
    const txStatus = setInterval(async () => {
        const status = await getBridgeStatus(txHash, fromChainId, toChainId);

        console.log(`SOURCE TX : ${status.result.sourceTxStatus}\nDEST TX : ${status.result.destinationTxStatus}`)

        if (status.result.destinationTxStatus == "COMPLETED") {
            console.log('DEST TX HASH :', status.result.destinationTransactionHash);
            clearInterval(txStatus);
        }
    }, 20000);
    });
  });
});
