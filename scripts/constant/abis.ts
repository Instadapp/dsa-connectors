export const abis: Record<string, any> = {
  core: {
    connectorsV2: require("./abi/core/connectorsV2.json"),
    instaIndex: require("./abi/core/instaIndex.json")
  },
  connectors: {
    "Basic-v1": require("./abi/connectors/basic.json"),
    basic: require("./abi/connectors/basic.json"),
    auth: require("./abi/connectors/auth.json"),
    "INSTAPOOL-A": require("./abi/connectors/instapool.json"),
    "INSTAPOOL-C": require("./abi/connectors/instapool-c.json")
  },
  basic: {
    erc20: require("./abi/basics/erc20.json")
  }
};
