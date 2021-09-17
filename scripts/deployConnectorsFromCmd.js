const hre = require("hardhat");
const { ethers } = hre;

const { connectors, networks } = require("./constant/cmdAssets");

let args = process.argv;
args = args.splice(2, args.length);
let params = {};

for (let i = 0; i < args.length; i += 2) {
    if (args[i][0] !== "-" || args[i][1] !== "-") {
        console.log("Please add '--' for the key");
        process.exit(-1);
    }
    let key = args[i].slice(2, args[i].length);
    params[key] = args[i + 1];
    if (key === "connector") {
        params[key] = connectors[args[i + 1]];
    }
}

if (!params.hasOwnProperty('connector')) {
    console.error("Should include connector params")
    process.exit(-1);
}

if(params['connector'] === undefined || params['connector'] === null) {
    console.error("Unsupported connector name");
    const keys = Object.keys(connectors);
    console.log("Currently supported connector names are: ", keys.join(","));
    console.log("If you want to add, please edit scripts/constant/cmdAssets.js");
    process.exit(1);   
}

if (!params.hasOwnProperty('network')) {
    console.error("Should include network params")
    process.exit(-1);
}

if (!params.hasOwnProperty('gas')) {
    console.error("Should include gas params")
    process.exit(-1);
}

let privateKey = process.env.PRIVATE_KEY;
let provider = new ethers.providers.JsonRpcProvider(hre.config.networks[params['network']].url);
// let wallet = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", provider);
let wallet = new ethers.Wallet(privateKey, provider);

const connectorName = params['connector'];

hre.network.name = params['networkName'];
hre.network.config = hre.config.networks[params['networkName']];
hre.network.provider = provider;

const main = async () => {
    const Connector = await ethers.getContractFactory(connectorName);
    const connector = await Connector.connect(wallet).deploy({ gasPrice: ethers.utils.parseUnits(params['gas'], "gwei") });
    await connector.deployed();

    console.log(`${connectorName} Deployed: ${connector.address}`);
    try {
        await hre.run("verify:verify", {
            address: connector.address,
            constructorArguments: []
        }
        )
    } catch (error) {
        console.log(`Failed to verify: ${connectorName}@${connector.address}`)
        console.log(error)
    }

    return connector.address
}

main()
    .then(() => {
        console.log("Done successfully");
        process.exit(0)
    })
    .catch(err => {
        console.log("error:", err);
        process.exit(1);
    })