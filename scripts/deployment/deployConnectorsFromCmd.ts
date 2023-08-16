import { execScript } from "../tests/command";
import inquirer from "inquirer";
import { connectors, connectMapping } from "./connectors";
import { join } from "path";

let start: number, end: number, runchain: string;

// async function connectorSelect(chain: string) {
//   let { connector } = await inquirer.prompt([
//     {
//       name: "connector",
//       message: "Which connector do you want to deploy?",
//       type: "list",
//       choices: connectors[chain],
//     },
//   ]);

//   return connector;
// }

async function deployRunner() {
  let { chain } = await inquirer.prompt([
    {
      name: "chain",
      message: "What chain do you want to deploy on?",
      type: "list",
      choices: ["mainnet", "polygon", "avalanche", "arbitrum", "optimism", "fantom", "base"]
    }
  ]);

  // let connector = await connectorSelect(chain);

  // let { choice } = await inquirer.prompt([
  //   {
  //     name: "choice",
  //     message: "Do you wanna select again?",
  //     type: "list",
  //     choices: ["yes", "no"],
  //   },
  // ]);

  // if (choice === "yes") {
  //   connector = await connectorSelect(chain);
  // }
  // connector = connectMapping[chain][connector];

  let { connector } = await inquirer.prompt([
    {
      name: "connector",
      message: "Enter the connector contract name? (ex: ConnectV2Paraswap)",
      type: "input"
    }
  ]);

  let { choice } = await inquirer.prompt([
    {
      name: "choice",
      message: "Do you wanna try deploy on hardhat first?",
      type: "list",
      choices: ["yes", "no"]
    }
  ]);

  runchain = choice === "yes" ? "hardhat" : chain;

  console.log(`Deploying ${connector} on ${runchain}, press (ctrl + c) to stop`);

  start = Date.now();
  await execScript({
    cmd: "npx",
    args: ["hardhat", "run", "scripts/deployment/deploy.ts", "--network", `${runchain}`],
    env: {
      connectorName: connector,
      networkType: chain
    }
  });
  end = Date.now();
}

deployRunner()
  .then(() => {
    console.log(`Done successfully, total time taken: ${(end - start) / 1000} sec`);
    process.exit(0);
  })
  .catch((err) => {
    console.log("error:", err);
    process.exit(1);
  });
