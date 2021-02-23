# DSA connectors

Connectors are standard proxy logics contract that let DeFi Smart Account (DSA) interact with various smart contracts, and make the important actions accessible like cross protocol interoperability.

DSAs are powerful because they can easily be extended with connectors. Every new connector that is added is immediately usable by any developer building on top of DSAs. Connectors can either be base connectors to protocols, auth connectors, higher level connectors with more specific use cases like optimized lending, or connectors to native liquidity pools.

You can create a PR to request a support for specific protocol or external contracts. Following is the list of all the supported connectors. Following is the list of all the primary connectors used to cast spells:

## MakerDAO

[Code](contracts/connectors_old/makerdao.sol)

### `open(collateralType)`

**Open a Maker vault** of the `collateralType`. E.g. "ETH-A", "USDC-B", etc...

### `close(vault)`

**Close a Maker vault**

`vault` - Vault ID (Use 0 for last opened vault)

### `deposit(vault, amt, getId, setId)`

**Deposit collateral to a Maker vault.**

`vault` - Vault ID (Use 0 for last opened vault)

`amt` - Amount of collteral to deposit

### `withdraw(vault, amt, getId, setId)`

**Withdraw collateral from a Maker vault.**

`vault` - Vault ID (Use 0 for last opened vault)

`amt` - Amount of collteral to withdraw

### `borrow(vault, amt, getId, setId)`

**Borrow DAI from a Maker vault.**

`vault` - Vault ID (Use 0 for last opened vault)

`amt` - Amount of DAI to borrow

### `payback(vault, amt, getId, setId)`

**Payback DAI to a Maker vault.**

`vault` - Vault ID (Use 0 for last opened vault)

`amt` - Amount of DAI to payback

### `withdrawLiquidated(vault, amt, getId, setId)`

**Withdraw leftover collateral after liquidation.**

`vault` - Vault ID (Use 0 for last opened vault)

`amt` - Amount of collateral to withdraw

### `depositAndBorrow(vault, depositAmt, borrowAmt, getIdDeposit, getIdBorrow, setIdDeposit, setIdBorrow)`

**Deposit collateral & borrow DAI from a vault.**

`vault` - Vault ID (Use 0 for last opened vault)

`depositAmt` - Amount of collateral to deposit

`borrowAmt` - Amount of DAI to borrow

## Compound

[Code](contracts/connectors_old/compound.sol)

### `deposit(token, amt, getId, setId)`

**Deposit token to Compound.**

`token` - Address of the token to deposit

`amt` - Amount of token to deposit

### `withdraw(token, amt, getId, setId)`

**Withdraw token from Compound.**

`token` - Address of the token to withdraw

`amt` - Amount of token to withdraw

### `borrow(token, amt, getId, setId)`

**Borrow token from Compound.**

`token` - Address of the token to borrow

`amt` - Amount of token to borrow

### `payback(token, amt, getId, setId)`

**Payback debt to Compound.**

`token` - Address of the token to payback

`amt` - Amount of token to payback

## Aave v1

[Code](contracts/connectors_old/aave.sol)

### `deposit(token, amt, getId, setId)`

**Deposit token to Aave.**

`token` - Address of the token to deposit

`amt` - Amount of token to deposit

### `withdraw(token, amt, getId, setId)`

**Withdraw token from Aave.**

`token` - Address of the token to withdraw

`amt` - Amount of token to withdraw

### `borrow(token, amt, getId, setId)`

**Borrow token from Aave.**

`token` - Address of the token to borrow

`amt` - Amount of token to borrow

### `payback(token, amt, getId, setId)`

**Payback debt to Aave.**

`token` - Address of the token to payback

`amt` - Amount of token to payback

## Aave v2

[Code](contracts/connectors_old/aave_v2.sol)

### `deposit(token, amt, getId, setId)`

**Deposit token to Aave.**

`token` - Address of the token to deposit

`amt` - Amount of token to deposit

### `withdraw(token, amt, getId, setId)`

**Withdraw token from Aave.**

`token` - Address of the token to withdraw

`amt` - Amount of token to withdraw

### `borrow(token, amt, rateMode, getId, setId)`

**Borrow token from Aave.**

`token` - Address of the token to borrow

`amt` - Amount of token to borrow

`rateMode` - Borrow interest rate mode (1 = Stable & 2 = Variable)

### `payback(token, amt, rateMode, getId, setId)`

**Payback debt to Aave.**

`token` - Address of the token to payback

`amt` - Amount of token to payback

`rateMode` - Borrow interest rate mode (1 = Stable & 2 = Variable)

