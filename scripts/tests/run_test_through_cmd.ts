import { promises as fs } from "fs";

import { join } from "path";
import { execScript } from "./command";

import { task } from "hardhat/config";


let start: number, end: number;

task("run_tests", "runs specified test on a specified chain")
.addPositionalParam("chain")
.addPositionalParam("test")
.setAction(async (taskArgs) => {
  const chain = taskArgs.chain;
  const test = taskArgs.test;
  await testRunner(chain,test)
  .then(() =>
    console.log(
      `🙌 finished the test runner, time taken ${(end - start) / 1000} sec`
    )
  )
  .catch((err) => console.error("❌ failed due to error: ", err));

});

async function testRunner(chain: string, testName: string) {

  const testsPath = join(__dirname, "../../test", chain);
  await fs.access(testsPath);
  const availableTests = await fs.readdir(testsPath);
  if (availableTests.length === 0) {
    throw new Error(`No tests available for ${chain}`);
  }

  start = Date.now();
  let path: string;
  if (testName === "all") {
    for (let test of availableTests) {
      path = join(testsPath, test);
      path += "/*";
      await execScript({
        cmd: "npx",
        args: ["hardhat", "test", path],
        env: {
          networkType: chain,
        },
      }).catch((err)=>console.log(`failed ${test}`))
    }
  } else {
    path = join(testsPath, testName);
    path += "/*";

    await execScript({
      cmd: "npx",
      args: ["hardhat", "test", path],
      env: {
        networkType: chain,
      },
    });
  }
  end = Date.now();
}