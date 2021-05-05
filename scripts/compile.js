const fs = require('fs')
const path = require('path')

const forbiddenStrings = ['selfdestruct']

const getConnectorsList = async () => {
  const connectorsList = []
  const connectorsRootsDirs = ['mainnet', 'polygon']
  for (let index = 0; index < connectorsRootsDirs.length; index++) {
    const root = `contracts/${connectorsRootsDirs[index]}/connectors`
    const dirs = fs.readdirSync(root)
    const files = dirs
      .filter(dir => fs.existsSync(`${root}/${dir}/main.sol`))
      .map(dir => ({
        path: `${root}/${dir}`,
        common: `contracts/${connectorsRootsDirs[index]}/common`
      }))
    connectorsList.push(...files)
  }
  return connectorsList
}

const checkCode = async (code, codePath) => {
  const forbidden = []
  for (let index = 0; index < forbiddenStrings.length; index++) {
    const str = forbiddenStrings[index]
    if (code.includes(str)) {
      forbidden.push(`found '${str}' in ${codePath}`)
    }
  }
  return forbidden
}

const checkLoop = async (parentPath, codePath = './main.sol') => {
  if (codePath.startsWith('@')) {
    codePath = path.resolve('node_modules', `./${codePath}`)
  } else {
    codePath = path.resolve(parentPath, codePath)
  }
  const code = fs.readFileSync(codePath, { encoding: 'utf8' })
  const forbidden = await checkCode(code, codePath)
  if (code.includes('import')) {
    const importsPathes = code
      .split('\n')
      .filter(str => str.includes('import') && str.includes('from') && str.includes('.sol'))
      .map(str => str.split('from')[1].replace(/["; ]/gi, ''))
    for (let index = 0; index < importsPathes.length; index++) {
      const childForbidden = await checkLoop(
        path.parse(codePath).dir,
        importsPathes[index]
      )
      forbidden.push(...childForbidden)
    }
  }
  return forbidden
}

(async function checkMain () {
  const forbidden = []
  const connectors = await getConnectorsList()
  for (let index = 0; index < connectors.length; index++) {
    const childForbidden = await checkLoop(connectors[index].path)
    forbidden.push(...childForbidden)
  }
  console.log(forbidden)
})()
