const fs = require('fs')
const path = require('path')
const { deprecate } = require('util')

const forbiddenStrings = ['selfdestruct']

const getConnectorsList = async () => {
  const connectors = []
  const connectorsRootsDirs = ['mainnet', 'polygon']
  for (let index = 0; index < connectorsRootsDirs.length; index++) {
    const root = `contracts/${connectorsRootsDirs[index]}/connectors`
    const dirs = [root]
    while (dirs.length) {
      const currentDir = dirs.pop()
      const subs = fs.readdirSync(currentDir, { withFileTypes: true })
      for (let index = 0; index < subs.length; index++) {
        const sub = subs[index]
        if (sub.isFile() && sub.name === 'main.sol') {
          connectors.push(currentDir)
        } else if (sub.isDirectory()) {
          dirs.push(`${currentDir}/${sub.name}`)
        }
      }
    }
  }
  return connectors.map(dir => ({ path: dir }))
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
  return codePath.endsWith('main.sol') ? { childForbidden: forbidden, code } : forbidden
}

const checkEvents = async (connector) => {
  const strs = connector.code.split('\n')
  let func = []
  let funcs = []
  let event = []
  const errors = []
  const warnings = []
  const events = []
  for (let index = 0; index < strs.length; index++) {
    const str = strs[index]
    if (str.includes('function')) {
      func = [str]
    } else if (func.length && !str.trim().startsWith('//')) {
      func.push(str)
    }
    if (func.length && str.startsWith(`${func[0].split('function')[0]}}`)) {
      funcs.push(func.map(str => str.trim()).join(' '))
      func = []
    }
  }
  const eventsPath = `${connector.path}/events.sol`
  if (fs.existsSync(eventsPath)) {
    const eventsCode = fs.readFileSync(eventsPath, { encoding: 'utf8' })
    const eventsStrs = eventsCode.split('\n')
    for (let index = 0; index < eventsStrs.length; index++) {
      const str = eventsStrs[index]
      if (str.includes('event')) {
        event = [str]
      } else if (event.length && !str.trim().startsWith('//')) {
        event.push(str)
      }
      if (event.length && str.includes(')')) {
        events.push(event.map(str => str.trim()).join(' '))
        event = []
      }
    }
    funcs = funcs
      .filter(str => {
        if ((str.includes('external') || str.includes('public')) &&
          str.includes('returns')) {
          const returns = str.split('returns')[1].split('(')[1].split(')')[0]
          return returns.includes('string') && returns.includes('bytes')
        }
        return false
      })
    const mainEvents = funcs
      .map(str => str.split('_eventName')[2].trim().split('"')[1])
      .filter(str => !!str)
    const eventNames = []
    for (let i1 = 0; i1 < mainEvents.length; i1++) {
      const mainEvent = mainEvents[i1]
      const name = mainEvent.split('(')[0]
      eventNames.push(name)
      const event = events.find(e => e.split('(')[0].split(' ')[1] === name)
      if (event) {
        const mainEventArgs = mainEvent.split('(')[1].split(')')[0].split(',').map(a => a.trim())
        const eventArgs = event.split('(')[1].split(')')[0].split(',').map(a => a.trim())
        if (mainEventArgs.length !== eventArgs.length) {
          errors.push(`arguments amount don't match for ${name} at ${eventsPath}`)
          continue
        }
        for (let i2 = 0; i2 < mainEventArgs.length; i2++) {
          if (!mainEventArgs[i2].startsWith(eventArgs[i2].split(' ')[0])) {
            errors.push(`invalid argument ${mainEventArgs[i2]} for ${name} at ${eventsPath}`)
            continue
          }
        }
      } else {
        errors.push(`event ${name} missing at ${eventsPath}`)
      }
    }
    if (mainEvents.length < events.length) {
      const deprecatedEvents = events.filter(e => {
        let used = false
        for (let index = 0; index < eventNames.length; index++) {
          if (e.split('(')[0].split(' ')[1] === eventNames[index]) used = true
        }
        return !used
      })
      warnings.push(`${deprecatedEvents.map(e => e.split('(')[0].split(' ')[1]).join(', ')} event(s) not used at ${connector.path}/main.sol`)
    }
  }
  return { eventsError: errors, eventsWarnings: warnings }
}

(async function checkMain () {
  const errors = []
  const warnings = []
  const connectors = await getConnectorsList()
  for (let index = 0; index < connectors.length; index++) {
    const { childForbidden, code } = await checkLoop(connectors[index].path)
    connectors[index].code = code
    const { eventsError, eventsWarnings } = await checkEvents(connectors[index])
    errors.push(...eventsError)
    errors.push(...childForbidden)
    warnings.push(...eventsWarnings)
  }
  console.log(`Total errors: ${errors.length}`)
  console.error(errors.join('\n'))
  console.log(`Total warnings: ${warnings.length}`)
  console.warn(warnings.join('\n'))
})()
