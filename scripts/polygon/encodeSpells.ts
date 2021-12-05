import { addresses } from "./constant/addresses";
import { abis } from "../constant/abis";
import { web3 } from "hardhat";

module.exports = function(spells: any[]) {
  const targets = spells.map((a) => a.connector);
  const calldatas = spells.map((a) => {
    const functionName = a.method;
    // console.log(functionName)
    const abi = abis.connectors[a.connector].find((b: { name: any }) => {
      return b.name === functionName;
    });
    // console.log(functionName)
    if (!abi) throw new Error("Couldn't find function");
    return web3.eth.abi.encodeFunctionCall(abi, a.args);
  });
  return [targets, calldatas];
};