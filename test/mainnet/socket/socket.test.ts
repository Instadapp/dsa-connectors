import { expect } from "chai";
import hre from "hardhat";
const { waffle, ethers } = hre;
const { provider } = waffle;
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
  let build_tx_data, quote

  const fromChainId = "1"
  const toChainId = "137"
  const recipient = "0xD625c7458Da1a0758dA8d3AC7f2c10180Bf0E506"

  const wallets = provider.getWallets();
  const [wallet0, wallet1, wallet2, wallet3] = wallets;
  const API_KEY = '645b2c8c-5825-4930-baf3-d9b997fcd88c';

  const DAI_ADDR_ETH = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const ETHADDR = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
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

  let getRouteToPass = (pathArray: Array<number>) => {
    if(pathArray[0] == 0) {
      let routeNum : number = pathArray[1]
      return routeNum
    } else {
      let routeNum : number = pathArray[0]
      return routeNum
    }
  }

  describe("Main", function () {

    it("should send DAI from ETH to Polygon", async function () {

      const quote = await getQuote(
        fromChainId, 
        DAI_ADDR_ETH, 
        toChainId,
        DAI_ADDR_POLYGON,
        "1000000000000000000",
        dsaWallet0.address,
        wallet0.address, 
        "true"
      );
      const route = quote.result.routes[0]
      const splitArr = route.userTxs[0].routePath.split("-");
      const routeToPass : number = getRouteToPass(splitArr);
      console.log("routeToPass: ", routeToPass);

      let apiReturnData = await getRouteTransactionData(route);

      const spells = [
        {
          connector: connectorName,
          method: "bridge",
          args: [DAI_ADDR_ETH, apiReturnData.result.txData, routeToPass, "1000000000000000000", '0']
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
      let receipt = await tx.wait();
      const txHash = receipt.transactionHash;

      console.log('Bridging Transaction : ', receipt.transactionHash);

      const txStatus = setInterval(async () => {
        const status = await getBridgeStatus(txHash, fromChainId, toChainId);
        console.log(`SOURCE TX : ${status.result.sourceTxStatus}\nDEST TX : ${status.result.destinationTxStatus}`)

        if (status.result.destinationTxStatus == "COMPLETED") {
            console.log('DEST TX HASH :', status.result.destinationTransactionHash);
            clearInterval(txStatus);
        }
      }, 80000);
    });

    it("should migrate ETH from Eth to Polygon", async function () {
      const quote = await getQuote(
        fromChainId, 
        ETHADDR, 
        toChainId, 
        DAI_ADDR_POLYGON, 
        "1000000000000000000", 
        dsaWallet0.address, 
        wallet0.address, 
        "true"
      );
      const route = quote.result.routes[0]
      const splitArr = route.userTxs[0].routePath.split("-");

      const routeToPass = getRouteToPass(splitArr);
      console.log("routeToPass: ", routeToPass);

      let apiReturnData = await getRouteTransactionData(route);

      const params: any = [
        apiReturnData.result.txData,
        ETHADDR,
        "1000000000000000000"
      ];

      const spells = [
        {
          connector: connectorName,
          method: "bridge",
          args: [ETHADDR, apiReturnData.result.txData, routeToPass, "1000000000000000000", '0']
        }
      ];

      const tx = await dsaWallet0.connect(wallet0).cast(...encodeSpells(spells), wallet0.address);
      let receipt = await tx.wait();
      const txHash = receipt.transactionHash;

      console.log('Bridging Transaction : ', receipt.transactionHash);

      const txStatus = setInterval(async () => {
        const status = await getBridgeStatus(txHash, fromChainId, toChainId);
        console.log(`SOURCE TX : ${status.result.sourceTxStatus}\nDEST TX : ${status.result.destinationTxStatus}`)

        if (status.result.destinationTxStatus == "COMPLETED") {
            console.log('DEST TX HASH :', status.result.destinationTransactionHash);
            clearInterval(txStatus);
        }
    }, 80000);
    });
  });
});
