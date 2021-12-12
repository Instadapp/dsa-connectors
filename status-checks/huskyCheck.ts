import checkMain from "./check";

(async function runHusky() {
  try {
    await checkMain();
  } catch (error) {
    process.exit(1);
  }
})();
