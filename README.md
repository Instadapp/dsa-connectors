# DSA connectors

Connectors are standard proxy logics contract that let DeFi Smart Account (DSA) interact with various smart contracts, and make the important actions accessible like cross protocol interoperability.

DSAs are powerful because they can easily be extended with connectors. Every new connector that is added is immediately usable by any developer building on top of DSAs. Connectors can either be base connectors to protocols, auth connectors, higher level connectors with more specific use cases like optimized lending, or connectors to native liquidity pools.

You can create a PR to request a support for specific protocol or external contracts. Following is the list of all the supported connectors. Following is the list of all the primary connectors used to cast spells:

## MakerDAO

[Code](contracts/connectors_old/makerdao.sol)

### `open(collateralType)`

**Open a Maker vault** of the `collateralType`. E.g. "ETH-A", "USDC-B", etc...

### `deposit(vault, amt, getId, setId)`

**Deposit collateral to a Maker vault.**

`vault` - Vault ID (Use 0 for last opened vault)

`amt` - Amount of collteral to deposit

### `withdraw(vault, amt, getId, setId)`

**Withdraw collateral from a Maker vault.**

`vault` - Vault ID (Use 0 for last opened vault)

`amt` - Amount of collteral to withdraw
