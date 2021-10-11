const hre = require("hardhat");
const hardhatConfig = require("../../hardhat.config");

async function forkReset(blockNumber) {
  await hre.network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: hardhatConfig.networks.hardhat.forking.url,
          blockNumber,
        },
      },
    ],
  });
}
async function sendEth(from, to, amount) {
  await from.sendTransaction({
    to: to,
    value: ethers.BigNumber.from(10).pow(18).mul(amount),
  });
}

module.exports = { forkReset, sendEth };
