const fs = require('fs')
const path = require('path')

const forbiddenStrings = ['selfdestruct']

const getConnectorsList = async () => {
  try {
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
  } catch (error) {
    return Promise.reject(error)
  }
}

const checkCodeForbidden = async (code, codePath) => {
  try {
    const forbidden = []
    for (let i1 = 0; i1 < forbiddenStrings.length; i1++) {
      const forbiddenStr = forbiddenStrings[i1]
      const strs = code.split('\n')
      for (let i2 = 0; i2 < strs.length; i2++) {
        if (strs[i2].includes(forbiddenStr)) {
          forbidden.push(`found '${forbiddenStr}' in ${codePath}:${i2 + 1}`)
        }
      }
    }
    return forbidden
  } catch (error) {
    return Promise.reject(error)
  }
}

const checkForbidden = async (parentPath, codePath = './main.sol') => {
  try {
    if (codePath.startsWith('@')) {
      codePath = path.resolve('node_modules', `./${codePath}`)
    } else {
      codePath = path.resolve(parentPath, codePath)
    }
    const code = fs.readFileSync(codePath, { encoding: 'utf8' })
    const forbidden = await checkCodeForbidden(code, codePath)
    if (code.includes('import')) {
      const importsPathes = code
        .split('\n')
        .filter(str => str.includes('import') && str.includes('from') && str.includes('.sol'))
        .map(str => str.split('from')[1].replace(/["; ]/gi, ''))
      for (let index = 0; index < importsPathes.length; index++) {
        const forbiddenErrors = await checkForbidden(
          path.parse(codePath).dir,
          importsPathes[index]
        )
        forbidden.push(...forbiddenErrors)
      }
    }
    return codePath.endsWith('main.sol') ? { forbiddenErrors: forbidden, code } : forbidden
  } catch (error) {
    return Promise.reject(error)
  }
}

const checkEvents = async (connector) => {
  try {
    const errors = []
    const warnings = []
    const eventsPath = `${connector.path}/events.sol`
    const mainPath = `${connector.path}/main.sol`
    if (connector.events.length) {
      const eventNames = []
      for (let i1 = 0; i1 < connector.mainEvents.length; i1++) {
        const mainEvent = connector.mainEvents[i1]
        const name = mainEvent.split('(')[0]
        eventNames.push(name)
        const event = connector.events.find(e => e.split('(')[0].split(' ')[1] === name)
        if (event) {
          const mainEventArgs = mainEvent.split('(')[1].split(')')[0].split(',').map(a => a.trim())
          const eventArgs = event.split('(')[1].split(')')[0].split(',').map(a => a.trim())
          if (mainEventArgs.length !== eventArgs.length) {
            errors.push(`arguments amount don't match for ${name} at ${mainPath}:${connector.mainEventsLines[i1]}`)
            continue
          }
          for (let i2 = 0; i2 < mainEventArgs.length; i2++) {
            if (!mainEventArgs[i2].startsWith(eventArgs[i2].split(' ')[0])) {
              errors.push(`invalid argument #${i2 + 1} for ${name} at ${mainPath}:${connector.mainEventsLines[i1]}`)
            }
          }
        } else {
          errors.push(`event ${name} missing at ${eventsPath}`)
        }
      }
      if (connector.mainEvents.length < connector.events.length) {
        const deprecatedEvents = connector.events.filter(e => {
          let used = false
          for (let index = 0; index < eventNames.length; index++) {
            if (e.split('(')[0].split(' ')[1] === eventNames[index]) used = true
          }
          return !used
        })
        warnings.push(`${deprecatedEvents.map(e => e.split('(')[0].split(' ')[1]).join(', ')} event(s) not used at ${connector.path}/main.sol`)
      }
    } else {
      warnings.push(`missing events file for ${connector.path}/main.sol`)
    }
    return { eventsErrors: errors, eventsWarnings: warnings }
  } catch (error) {
    return Promise.reject(error)
  }
}

const getCommments = async (strs) => {
  try {
    const comments = []
    let type
    for (let index = strs.length - 1; index >= 0; index--) {
      const str = strs[index]
      if (!type) {
        if (str.trim().startsWith('//')) {
          type = 'single'
        } else if (str.trim().startsWith('*/')) {
          type = 'multiple'
        }
      }
      if (type === 'single' && str.trim().startsWith('//')) {
        comments.push(str.replace(/[/]/gi, '').trim())
      } else if (type === 'multiple' && !str.trim().startsWith('/**') && !str.trim().startsWith('*/')) {
        comments.push(str.replace(/[*]/gi, '').trim())
      } else if (type === 'single' && !str.trim().startsWith('//')) {
        break
      } else if (type === 'multiple' && str.trim().startsWith('/**')) {
        break
      }
    }
    return comments
  } catch (error) {
    return Promise.reject(error)
  }
}

const parseCode = async (connector) => {
  try {
    const strs = connector.code.split('\n')
    const events = []
    const eventsFirstLines = []
    let func = []
    let funcs = []
    let event = []
    let mainEvents = []
    let firstLine
    let mainEventsLines = []
    for (let index = 0; index < strs.length; index++) {
      const str = strs[index]
      if (str.includes('function') && !str.trim().startsWith('//')) {
        func = [str]
        firstLine = index + 1
      } else if (func.length && !str.trim().startsWith('//')) {
        func.push(str)
      }
      if (func.length && str.startsWith(`${func[0].split('function')[0]}}`)) {
        funcs.push({
          raw: func.map(str => str.trim()).join(' '),
          comments: await getCommments(strs.slice(0, firstLine)),
          firstLine
        })
        func = []
      }
    }
    const allPublicFuncs = funcs
      .filter(({ raw }) => {
        return raw.includes('external') || raw.includes('public')
      })
      .map(f => {
        const name = f.raw.split('(')[0].split('function')[1].trim()
        return {
          ...f,
          name
        }
      })
    funcs = allPublicFuncs
      .filter(({ raw }) => {
        if (raw.includes('returns')) {
          const returns = raw.split('returns')[1].split('(')[1].split(')')[0]
          return returns.includes('string') && returns.includes('bytes')
        }
        return false
      })
      .map(f => {
        const args = f.raw.split('(')[1].split(')')[0].split(',')
          .map(arg => arg.trim())
          .filter(arg => arg !== '')
        return {
          ...f,
          args
        }
      })
    const eventsPath = `${connector.path}/events.sol`
    if (fs.existsSync(eventsPath)) {
      mainEvents = funcs
        .map(({ raw }) => raw.split('_eventName')[2].trim().split('"')[1])
        .filter(raw => !!raw)
      mainEventsLines = mainEvents.map(me => strs.findIndex(str => str.includes(me)) + 1)
      const eventsCode = fs.readFileSync(eventsPath, { encoding: 'utf8' })
      const eventsStrs = eventsCode.split('\n')
      for (let index = 0; index < eventsStrs.length; index++) {
        const str = eventsStrs[index]
        if (str.includes('event')) {
          event = [str]
          firstLine = index + 1
        } else if (event.length && !str.trim().startsWith('//')) {
          event.push(str)
        }
        if (event.length && str.includes(')')) {
          events.push(event.map(str => str.trim()).join(' '))
          eventsFirstLines.push(firstLine)
          event = []
        }
      }
    }
    return {
      ...connector,
      events,
      eventsFirstLines,
      mainEvents,
      mainEventsLines,
      funcs,
      allPublicFuncs
    }
  } catch (error) {
    return Promise.reject(error)
  }
}

const checkComments = async (connector) => {
  try {
    const errors = []
    for (let i1 = 0; i1 < connector.funcs.length; i1++) {
      const func = connector.funcs[i1]
      for (let i2 = 0; i2 < func.args.length; i2++) {
        const argName = func.args[i2].split(' ').pop()
        if (!func.comments.some(
          comment => comment.startsWith('@param') && comment.split(' ')[1] === argName
        )) {
          errors.push(`argument ${argName} has no @param for function ${func.name} at ${connector.path}/main.sol:${func.firstLine}`)
        }
      }
      const reqs = ['@dev', '@notice']
      for (let i3 = 0; i3 < reqs.length; i3++) {
        if (!func.comments.some(comment => comment.startsWith(reqs[i3]))) {
          errors.push(`no ${reqs[i3]} for function ${func.name} at ${connector.path}/main.sol:${func.firstLine}`)
        }
      }
    }
    return errors
  } catch (error) {
    return Promise.reject(error)
  }
}

const checkPublicFuncs = async (connector) => {
  try {
    const errors = []
    for (let i1 = 0; i1 < connector.allPublicFuncs.length; i1++) {
      const { raw, firstLine, name } = connector.allPublicFuncs[i1]
      if (!raw.includes('payable')) {
        errors.push(`public function ${name} is not payable at ${connector.path}/main.sol:${firstLine}`)
      }
    }
    return errors
  } catch (error) {
    return Promise.reject(error)
  }
}

const checkName = async (connector) => {
  try {
    const strs = connector.code.split('\n')
    let haveName = false
    for (let index = strs.length - 1; index > 0; index--) {
      const str = strs[index]
      if (str.includes('string') && str.includes('public') && str.includes('name = ')) {
        haveName = true
      }
    }
    return haveName ? [] : [`name variable missing in ${connector.path}/main.sol`]
  } catch (error) {
    return Promise.reject(error)
  }
}

const checkHeadComments = async (connector) => {
  try {
    const errors = []
    const strs = connector.code.split('\n')
    let haveTitle = false
    let haveDev = false
    for (let index = 0; index < strs.length; index++) {
      if (!strs[index].includes('{')) {
        if (strs[index].includes('@title')) haveTitle = true
        if (strs[index].includes('@dev')) haveDev = true
      } else {
        break
      }
    }
    if (!haveTitle) errors.push(`@title missing in ${connector.path}/main.sol`)
    if (!haveDev) errors.push(`@dev missing in ${connector.path}/main.sol`)
    return errors
  } catch (error) {
    return Promise.reject(error)
  }
}

async function checkMain () {
  try {
    const errors = []
    const warnings = []
    const connectors = await getConnectorsList()
    for (let index = 0; index < connectors.length; index++) {
      const { forbiddenErrors, code } = await checkForbidden(connectors[index].path)
      connectors[index].code = code
      connectors[index] = await parseCode(connectors[index])
      const { eventsErrors, eventsWarnings } = await checkEvents(connectors[index])
      const commentsErrors = await checkComments(connectors[index])
      const nameErrors = await checkName(connectors[index])
      const headCommentsErrors = await checkHeadComments(connectors[index])
      const publicFuncsErrors = await checkPublicFuncs(connectors[index])

      errors.push(...forbiddenErrors)
      errors.push(...eventsErrors)
      errors.push(...commentsErrors)
      errors.push(...nameErrors)
      errors.push(...headCommentsErrors)
      errors.push(...publicFuncsErrors)
      warnings.push(...eventsWarnings)
    }
    if (errors.length) {
      console.log('\x1b[31m%s\x1b[0m', `Total errors: ${errors.length}`)
      errors.forEach(error => console.log('\x1b[31m%s\x1b[0m', error))
    } else {
      console.log('\x1b[32m%s\x1b[0m', 'No Errors Found')
    }
    if (warnings.length) {
      console.log('\x1b[33m%s\x1b[0m', `Total warnings: ${warnings.length}`)
      warnings.forEach(warning => console.log('\x1b[33m%s\x1b[0m', warning))
    } else {
      console.log('\x1b[32m%s\x1b[0m', 'No Warnings Found')
    }
    if (errors.length) return Promise.reject(errors.join('\n'))
  } catch (error) {
    console.error('check execution error:', error)
  }
}
module.exports = checkMain
