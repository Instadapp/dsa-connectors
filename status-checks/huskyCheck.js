const checkMain = require('./check');

(async function runHusky () {
  try {
    await checkMain()
  } catch (error) {
    process.exit(1)
  }
})()