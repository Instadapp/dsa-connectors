module.exports = {
  core: {
    connectorsV2: require("./abi/core/connectorsV2.json"),
    instaIndex: require("./abi/core/instaIndex.json"),
  },
  connectors: {
    "Basic-v1": require("./abi/connectors/basic.json"),
    basic: require("./abi/connectors/basic.json"),
    auth: require("./abi/connectors/auth.json"),
  },
  basic: {
    erc20: require("./abi/basics/erc20.json"),
  },
};
