import hre, { ethers, network } from "hardhat";
import hardhatConfig from "../../../hardhat.config";

export async function forkReset(blockNumber: any) {
  await hre.network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          // @ts-ignore
          jsonRpcUrl: hardhatConfig.networks.hardhat.forking.url,
          blockNumber
        }
      }
    ]
  });
}

export async function mineBlock(timestamp: any) {
  await network.provider.request({
    method: "evm_mine",
    params: [timestamp]
  });
}

export async function sendEth(from: any, to: any, amount: any) {
  await from.sendTransaction({
    to: to,
    value: ethers.BigNumber.from(10).pow(18).mul(amount)
  });
}

export async function mineNBlock(blockCount: any, secondsBetweenBlock: any) {
  const blockBefore = await ethers.provider.getBlock("latest");
  const maxMinedBlockPerBatch = 1000;
  let blockToMine = blockCount;
  let blockTime = blockBefore.timestamp;
  while (blockToMine > maxMinedBlockPerBatch) {
    // eslint-disable-next-line @typescript-eslint/no-loop-func
    const minings: any = [maxMinedBlockPerBatch].map((_v, i) => {
      const newTs = blockTime + i + (secondsBetweenBlock || 1);
      return mineBlock(newTs);
    });
    // eslint-disable-next-line no-await-in-loop
    await Promise.all(minings);
    blockToMine -= maxMinedBlockPerBatch;
    blockTime = blockTime + maxMinedBlockPerBatch - 1 + maxMinedBlockPerBatch * (secondsBetweenBlock || 1);
  }
  const minings = [blockToMine].map((_v, i) => {
    const newTs = blockTime + i + (secondsBetweenBlock || 1);
    return mineBlock(newTs);
  });
  // eslint-disable-next-line no-await-in-loop
  await Promise.all(minings);
}
