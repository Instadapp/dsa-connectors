const abis = require("./constant/abis");
const addresses = require("./constant/addresses");
const { web3 } = hre;

const encodeSpells = require("./encodeSpells.js")


module.exports = function (spells) {
    const encodeSpellsData = encodeSpells(spells);
    const targetType = "string[]";
    let argTypes = [targetType, "bytes[]"];
    return web3.eth.abi.encodeParameters(argTypes, [
        encodeSpellsData[0],
        encodeSpellsData[1],
    ]);
};
