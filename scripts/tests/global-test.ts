import { promises as fs } from "fs";

import { join } from "path";
import { execScript } from "./command";

let start: number, end: number;

async function testRunner() {
  const chain = ["avalanche", "mainnet", "polygon", "arbitrum", "optimism"];
  start = Date.now();

  for (let ch of chain) {
    console.log(`📗Running test for %c${ch}: `, "blue");
    let path: string;
    const testsPath = join(__dirname, "../../test", ch);
    await fs.access(testsPath);
    const availableTests = await fs.readdir(testsPath);

    if (availableTests.length !== 0) {
      for (let test of availableTests) {
        path = join(testsPath, test);
        path += "/*";
        await execScript({
          cmd: "npx",
          args: ["hardhat", "test", path],
          env: {
            networkType: ch,
          },
        });
      }
    }
  }

  end = Date.now();
}

testRunner()
  .then(() =>
    console.log(
      `🙌 finished running the test, total time taken ${(end - start) /
        1000} sec`
    )
  )
  .catch((err) => console.error("❌ failed due to error: ", err));
