module.exports = {
  core: {
    connectorsV2: require("./abi/core/connectorsV2.json"),
    instaIndex: require("./abi/core/instaIndex.json"),
  },
  connectors: {
    "Basic-v1": require("./abi/connectors/basic.json"),
    basic: require("./abi/connectors/basic.json"),
    auth: require("./abi/connectors/auth.json"),
    "INSTAPOOL-A": require("./abi/connectors/instapool.json"),
    "BASIC-A": require("./abi/connectors/basic.json")
  },
  basic: {
    erc20: require("./abi/basics/erc20.json"),
  },
};
