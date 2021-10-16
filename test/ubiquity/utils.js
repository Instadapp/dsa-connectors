const hre = require("hardhat");
const hardhatConfig = require("../../hardhat.config");

async function forkReset(blockNumber) {
  await hre.network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: hardhatConfig.networks.hardhat.forking.url,
          blockNumber
        }
      }
    ]
  });
}

async function mineBlock(timestamp) {
  await network.provider.request({
    method: "evm_mine",
    params: [timestamp]
  });
}

async function sendEth(from, to, amount) {
  await from.sendTransaction({
    to: to,
    value: ethers.BigNumber.from(10).pow(18).mul(amount)
  });
}

async function mineNBlock(blockCount, secondsBetweenBlock) {
  const blockBefore = await ethers.provider.getBlock("latest");
  const maxMinedBlockPerBatch = 1000;
  let blockToMine = blockCount;
  let blockTime = blockBefore.timestamp;
  while (blockToMine > maxMinedBlockPerBatch) {
    // eslint-disable-next-line @typescript-eslint/no-loop-func
    const minings = [...Array(maxMinedBlockPerBatch).keys()].map((_v, i) => {
      const newTs = blockTime + i + (secondsBetweenBlock || 1);
      return mineBlock(newTs);
    });
    // eslint-disable-next-line no-await-in-loop
    await Promise.all(minings);
    blockToMine -= maxMinedBlockPerBatch;
    blockTime = blockTime + maxMinedBlockPerBatch - 1 + maxMinedBlockPerBatch * (secondsBetweenBlock || 1);
  }
  const minings = [...Array(blockToMine).keys()].map((_v, i) => {
    const newTs = blockTime + i + (secondsBetweenBlock || 1);
    return mineBlock(newTs);
  });
  // eslint-disable-next-line no-await-in-loop
  await Promise.all(minings);
}

module.exports = { forkReset, sendEth, mineNBlock };
