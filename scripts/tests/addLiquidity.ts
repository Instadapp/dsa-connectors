import { ethers, network } from "hardhat";

import { impersonateAccounts } from "./impersonate";
import { tokenMapping as mainnetMapping } from "./mainnet/tokens";
import { tokenMapping as polygonMapping } from "./polygon/tokens";
import { tokenMapping as avalancheMapping } from "./avalanche/tokens";
import { tokenMapping as optimismMapping } from "./optimism/tokens";
import { tokenMapping as arbitrumMapping } from "./arbitrum/tokens";
import { tokenMapping as fantomMapping } from "./fantom/tokens";

const mineTx = async (tx: any) => {
  await (await tx).wait();
};

const tokenMapping: Record<string, Record<string, any>> = {
  mainnet: mainnetMapping,
  polygon: polygonMapping,
  avalanche: avalancheMapping,
  optimism: optimismMapping,
  arbitrum: arbitrumMapping,
  fantom: fantomMapping
};

export async function addLiquidity(tokenName: string, address: any, amt: any) {
  const [signer] = await ethers.getSigners();
  tokenName = tokenName.toLowerCase();
  const chain = String(process.env.networkType);
  if (!tokenMapping[chain][tokenName]) {
    throw new Error(`Add liquidity doesn't support the following token: ${tokenName}`);
  }

  const token = tokenMapping[chain][tokenName];
  const [impersonatedSigner] = await impersonateAccounts([token.impersonateSigner]);

  // send 2 eth to cover any tx costs.
  await network.provider.send("hardhat_setBalance", [
    impersonatedSigner.address,
    ethers.utils.parseEther("2").toHexString()
  ]);

  await token.process(impersonatedSigner, address, amt);
}
