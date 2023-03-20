# Yearn ERC4626 Router

This repository contains an open-source ERC4626 Router implementation specific to the Yearn V3 vaults using [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626), including ERC4626Router (the canonical ERC-4626 multicall router). Powered by [forge](https://github.com/gakonst/foundry/tree/master/forge) and [solmate](https://github.com/Rari-Capital/solmate).

This repository and code was made extending the original [ERC4626 Router](https://github.com/fei-protocol/ERC4626).

## About ERC-4626

[EIP-4626: The Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626) is an ethereum application developer interface for building token vaults and strategies. It is meant to consolidate development efforts around "single token strategies" such as lending, yield aggregators, and single-sided staking.

## ERC4626Router and Base

ERC-4626 standardizes the interface around depositing and withdrawing tokens from strategies.

The ERC4626 Router is an ecosystem utility contract (like WETH) which can route tokens in and out of multiple ERC-4626 strategies in a single call. Its architecture was inspired by the [Uniswap V3 multicall router](https://github.com/Uniswap/v3-periphery/blob/main/contracts/SwapRouter.sol).

Basic supported features include:
* withdrawing from some Vault A and redepositing to Vault B
* wrapping and unwrapping WETH
* managing token approvals/transfers
* slippage protection

Ultimately the ERC4626 router can support an arbitrary number of withdrawals, deposits, and even distinct token types in a single call, subject to the block gas limit.

The router is split between the base [ERC4626RouterBase](https://github.com/Schlagonia/Yearn-ERC4626-Router/blob/master/src/Yearn4626RouterBase.sol) which only handles the ERC4626 mutable methods (deposit/withdraw/mint/redeem) and the main router [ERC4626Router](https://github.com/Schlagonia/Yearn-ERC4626-Router/blob/master/src/Yearn4626Router.sol) which includes support for common routing flows and max logic.

### Using the Router
The router is a multicall-style router, meaning it can atomically perform any number of supported actions on behalf of the message sender.

Some example user flows are listed below.

Vault deposit (requires ERC-20 approval of vault underlying asset before calling OR use a self-permit):
- PeripheryPayments.approve(asset, vault, amount) approves the vault to spend asset of the router
- ERC4626Router.depositToVault

WETH vault redeem (requires the router to have ERC-20 approval of the vault shares before calling OR use a self-permit):
- ERC4626Router.redeem *to* the router
- PeripheryPayments.unwrapWETH9 *to* the user destination

2 to 1 vault consolidation (requires ERC-20 approval of both source vault underlying assets OR self-permit):
- ERC4626RouterBase.withdraw (or redeem) on vault A *to* the router
- ERC4626RouterBase.withdraw (or redeem) on vault B *to* the router
- PeripheryPayments.approve(asset, vault C, amount) approves the vault to spend asset of the router
- ERC4626RouterBase.deposit on destination vault C

---
It is REQUIRED to use multicall to interact across multi-step user flows. The router is stateless other than holding token approvals for vaults it interacts with. Any tokens that end a transaction in the router can be permissionlessly withdrawn by any address, likely an MEV searcher, so make sure to complete all multicalls with token withdrawals to an end user address.

It is recommended to max approve vaults, and check whether a vault is already approved before interacting with the vault. This can save user gas. In cases where the number of required steps in a user flow is reduced to 1, a direct call can be used instead of multicall.

---
[ERC4626RouterBase](https://github.com/Schlagonia/Yearn-ERC4626-Router/blob/master/src/Yearn4626RouterBase.sol) - basic ERC4626 methods

[ERC4626Router](https://github.com/Schlagonia/Yearn-ERC4626-Router/blob/master/src/Yearn4626Router.sol) - combined ERC4626 methods

[PeripheryPayments](https://github.com/Schlagonia/Yearn-ERC4626-Router/blob/master/src/external/PeripheryPayments.sol) - WETH and ERC-20 utility methods

[Multicall](https://github.com/Schlagonia/Yearn-ERC4626-Router/blob/master/src/external/Multicall.sol) - multicall utility

[SelfPermit](https://github.com/Schlagonia/Yearn-ERC4626-Router/blob/master/src/external/SelfPermit.sol) - user approvals to the router with EIP-712 and EIP-2612



