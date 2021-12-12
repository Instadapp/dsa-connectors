import fs from "fs";
import hre from "hardhat"
const { ethers, network, config } = hre;

let args = process.argv;
args = args.splice(2, args.length);
let params: Record<string, string> = {};

for (let i = 0; i < args.length; i += 2) {
  if (args[i][0] !== "-" || args[i][1] !== "-") {
    console.log("Please add '--' for the key");
    process.exit(-1);
  }
  let key = args[i].slice(2, args[i].length);
  params[key] = args[i + 1];
}

if (!params.hasOwnProperty("connector")) {
  console.error("Should include connector params");
  process.exit(-1);
}

if (!params.hasOwnProperty("network")) {
  console.error("Should include network params");
  process.exit(-1);
}

if (!params.hasOwnProperty("gasPrice")) {
  console.error("Should include gas params");
  process.exit(-1);
}

let privateKey = String(process.env.PRIVATE_KEY);
let provider = new ethers.providers.JsonRpcProvider(
  config.networks[params["network"]].url
);
let wallet = new ethers.Wallet(privateKey, provider);

network.name = params["networkName"];
network.config = config.networks[params["networkName"]];
network.provider = provider;
let contracts: (string | string[])[] = [];

const parseFile = async (filePath: fs.PathOrFileDescriptor) => {
  const data = fs.readFileSync(filePath, "utf-8");
  let parsedData = data.split("contract ");
  parsedData = parsedData[parsedData.length - 1].split(" ");
  return parsedData[0];
};

const parseDir = async (root: string | any[], basePath: string, addPath: string) => {
  for (let i = 0; i < root.length; i++) {
    addPath = "/" + root[i];
    const dir = fs.readdirSync(basePath + addPath);
    if (dir.indexOf("main.sol") !== -1) {
      const fileData = await parseFile(basePath + addPath + "/main.sol");
      contracts.push(fileData);
    } else {
      await parseDir(dir, basePath + addPath, "");
    }
  }
};

const main = async () => {
  const mainnet = fs.readdirSync("./contracts/mainnet/connectors/");
  const polygon = fs.readdirSync("./contracts/polygon/connectors/");
  let basePathMainnet = "./contracts/mainnet/connectors/";
  let basePathPolygon = "./contracts/polygon/connectors/";

  const connectorName = params["connector"];

  await parseDir(mainnet, basePathMainnet, "");
  await parseDir(polygon, basePathPolygon, "");

  if (contracts.indexOf(connectorName) === -1) {
    throw new Error(
      "can not find the connector!\n" +
        "supported connector names are:\n" +
        contracts.join("\n")
    );
  }

  const Connector = await ethers.getContractFactory(connectorName);
  const connector = await Connector.connect(wallet).deploy({
    gasPrice: ethers.utils.parseUnits(params["gasPrice"], "gwei"),
  });
  await connector.deployed();

  console.log(`${connectorName} Deployed: ${connector.address}`);
  try {
    await hre.run("verify:verify", {
      address: connector.address,
      constructorArguments: [],
    });
  } catch (error) {
    console.log(`Failed to verify: ${connectorName}@${connector.address}`);
    console.log(error);
  }

  return connector.address;
};

main()
  .then(() => {
    console.log("Done successfully");
    process.exit(0);
  })
  .catch((err) => {
    console.log("error:", err);
    process.exit(1);
  });
