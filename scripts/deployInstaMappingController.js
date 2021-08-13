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

    const InstaMappingController = await ethers.getContractFactory('InstaMappingController')
    const instaMappingController = await InstaMappingController.deploy()
    await instaMappingController.deployed()

    console.log('InstaMappingController deployed: ', instaMappingController.address)

    if (hre.network.name === 'mainnet') {
        await hre.run('verify:verify', {
          address: instaMappingController.address,
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
