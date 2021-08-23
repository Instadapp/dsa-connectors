const hre = require('hardhat')
const { ethers } = hre

async function main () {
    if (hre.network.name === 'mainnet') {
        console.log(
        '\n\n Deploying Contracts to mainnet. Hit ctrl + c to abort'
        )
    } else if (hre.network.name === 'hardhat') {
        console.log(
        '\n\n Deploying Contracts to hardhat.'
        )
    }

    const mappingContract = "CONTRACT_NAME"

    const InstaProtocolMapping = await ethers.getContractFactory(mappingContract)
    const instaProtocolMapping = await InstaProtocolMapping.deploy()
    await instaProtocolMapping.deployed()

    console.log(`${mappingContract} deployed: `, instaProtocolMapping.address)

    if (hre.network.name === 'mainnet') {
        await hre.run('verify:verify', {
          address: instaProtocolMapping.address,
          constructorArguments: []
        })
    } else if (hre.network.name === 'hardhat') {
        console.log("Contracts deployed.")
    }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })
