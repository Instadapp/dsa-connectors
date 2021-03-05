# DSA connectors

Connectors are standard proxy logics contract that let DeFi Smart Account (DSA) interact with various smart contracts, and make the important actions accessible like cross protocol interoperability.

DSAs are powerful because they can easily be extended with connectors. Every new connector that is added is immediately usable by any developer building on top of DSAs. Connectors can either be base connectors to protocols, auth connectors, higher level connectors with more specific use cases like optimized lending, or connectors to native liquidity pools.

You can create a PR to request a support for specific protocol or external contracts. Following is the list of all the supported connectors. Following is the list of all the primary connectors used to cast spells:

[Read this post to learn about getId and setId used in the connectors](https://discuss.instadapp.io/t/how-to-use-getid-setid/104)

## Authority

[Code](contracts/connectors_old/authority.sol)

### `add(authority)`

**Add an address authority**

`authority` - Address of the authority to add

### `remove(authority)`

**Remove an address authority**

`authority` - Address of the authority to remove

## Basic

[Code](contracts/connectors_old/basic.sol)

### `deposit(erc20, amt, getId, setId)`

**Deposit a token or ETH to DSA.**

`erc20` - Address of the token to deposit. ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE

`amt` - Amount of token to deposit

In case of an ERC20 Token, allowance must be given to DSA before depositing

### `withdraw(erc20, amt, getId, setId)`

**Withdraw a token or ETH from DSA.**

`erc20` - Address of the token to withdraw. ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE

`amt` - Amount of token to withdraw

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

## COMP

[Code](contracts/connectors_old/COMP.sol)

### `ClaimComp(setId)`

**Claim unclaimed COMP**

### `ClaimCompTwo(tokens, setId)`

**Claim unclaimed COMP**

`tokens` - List of tokens supplied or borrowed

### `ClaimCompThree(supplyTokens, borrowTokens, setId)`

**Claim unclaimed COMP**

`supplyTokens` - List of tokens supplied

`borrowTokens` - List of tokens borrowed

### `delegate(delegatee)`

**Delegate COMP votes**

`delegatee` - Address of the delegatee

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

## dYdX

[Code](contracts/connectors_old/dydx.sol)

### `deposit(token, amt, getId, setId)`

**Deposit token to dYdX.**

`token` - Address of the token to deposit

`amt` - Amount of token to deposit

### `withdraw(token, amt, getId, setId)`

**Withdraw token from dYdX.**

`token` - Address of the token to withdraw

`amt` - Amount of token to withdraw

### `borrow(token, amt, getId, setId)`

**Borrow token from dYdX.**

`token` - Address of the token to borrow

`amt` - Amount of token to borrow

### `payback(token, amt, getId, setId)`

**Payback debt to dYdX.**

`token` - Address of the token to payback

`amt` - Amount of token to payback

## Uniswap

[Code](contracts/connectors_old/uniswap.sol)

### `deposit(tokenA, tokenB, amtA, unitAmt, slippage, getId, setId)`

**Deposit liquidity to tokenA/tokenB pool**

`tokenA` - Address of token A

`tokenB` - Address of token B

`amtA` - Amount of token A to deposit

`unitAmt` - Unit amount of amtB/amtA with slippage.

`slippage` - Slippage amount in wei


### `withdraw(tokenA, tokenB, uniAmt, unitAmtA, unitAmtB, getId, setId)`

**Withdraw liquidity from tokenA/tokenB pool**

`tokenA` - Address of token A

`tokenB` - Address of token B

`uniAmt` - Amount of LP tokens to withdraw

`unitAmtA` - Unit amount of amtA/uniAmt with slippage.

`unitAmtB` - Unit amount of amtB/uniAmt with slippage.

### `buy(buyAddr, sellAddr, buyAmt, unitAmt, getId, setId)`

**Buy a token/ETH**

`buyAddr` - Address of the buying token

`sellAddr` - Address of the selling token

`buyAmt` - Amount of tokens to buy

`unitAmt` - Unit amount of sellAmt/buyAmt with slippage

### `sell(buyAddr, sellAddr, sellAmt, unitAmt, getId, setId)`

**Sell a token/ETH**

`buyAddr` - Address of the buying token

`sellAddr` - Address of the selling token

`sellAmt` - Amount of tokens to sell

`unitAmt` - Unit amount of buyAmt/sellAmt with slippage

## 1Inch

[Code](contracts/connectors_old/1inch.sol)

### `sell(buyAddr, sellAddr, sellAmt, unitAmt, getId, setId)`

**Sell ETH/ERC20 using 1proto**

`buyAddr` - Address of the buying token

`sellAddr` - Address of the selling token

`sellAmt` - Amount of tokens to sell

`unitAmt` - Unit amount of buyAmt/sellAmt with slippage

### `sellTwo(buyAddr, sellAddr, sellAmt, unitAmt, getId, setId)`

**Sell ETH/ERC20 using 1proto**

`buyAddr` - Address of the buying token

`sellAddr` - Address of the selling token

`sellAmt` - Amount of tokens to sell

`unitAmt` - Unit amount of buyAmt/sellAmt with slippage

`[]distribution` - Distribution of swap across different dex.

`disableDexes` - Disable a dex. (To disable none: 0)

### `sellTwo(buyAddr, sellAddr, sellAmt, unitAmt, getId, setId)`

**Sell ETH/ERC20 using 1inch**

Use [1Inch API](https://docs.1inch.exchange/api/) for calldata

`buyAddr` - Address of the buying token

`sellAddr` - Address of the selling token

`sellAmt` - Amount of tokens to sell

`unitAmt` - Unit amount of buyAmt/sellAmt with slippage

`callData` - Data from 1inch API
