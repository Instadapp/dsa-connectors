import hre from "hardhat";
const { web3 } = hre;

import { encodeSpells } from "./encodeSpells";

export default function encodeFlashcastData(spells: any) {
  const encodeSpellsData = encodeSpells(spells);
  let argTypes = ["string[]", "bytes[]"];
  return web3.eth.abi.encodeParameters(argTypes, [
    encodeSpellsData[0],
    encodeSpellsData[1],
  ]);
};
