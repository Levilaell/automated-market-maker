# AMM Protocol

A Uniswap V2-inspired Automated Market Maker built in Solidity. Enables trustless token swaps and liquidity provision using the constant product formula `x * y = k`.

## Overview

The contract itself is an ERC20 token — LP tokens are minted directly by the AMM to represent each liquidity provider's share of the pool. No external token contract needed.

## Architecture

```
AMM.sol   — core AMM logic + LP token (inherits ERC20)
```

### Key Parameters

| Parameter            | Value                                                   | Description                                 |
| -------------------- | ------------------------------------------------------- | ------------------------------------------- |
| Swap fee             | 0.3%                                                    | Deducted from input amount, accrues to LPs  |
| First liquidity      | `sqrt(amountA * amountB)`                               | Neutralizes price manipulation by first LP  |
| Subsequent liquidity | `min(amountA/reserveA, amountB/reserveB) * totalSupply` | Proportional, penalizes imbalanced deposits |

## Core Functions

### `addLiquidity(uint amountA, uint amountB)`

Deposits both tokens into the pool and mints LP tokens in return.

**First deposit** — pool is empty, price is set by the depositor:

```
liquidity = sqrt(amountA * amountB)
```

**Subsequent deposits** — must match existing ratio:

```
liquidity = min(amountA * totalSupply / reserveA,
                amountB * totalSupply / reserveB)
```

The `min` penalizes imbalanced deposits — the limiting side determines LP tokens received.

### `removeLiquidity(uint liquidity)`

Burns LP tokens and returns the proportional share of both reserves:

```
amountA = reserveA * liquidity / totalSupply
amountB = reserveB * liquidity / totalSupply
```

Includes any fees accumulated since deposit.

### `swap(address tokenIn, uint amountIn)`

Swaps one token for the other. A single formula handles both directions via a ternary:

```solidity
(reserveIn, reserveOut, tokenOut) = tokenIn == tokenA
    ? (reserveA, reserveB, tokenB)
    : (reserveB, reserveA, tokenA)
```

The 0.3% fee is applied on the input before the constant product calculation:

```
amountInWithFee = amountIn * 997 / 1000
amountOut = reserveOut * amountInWithFee / (reserveIn + amountInWithFee)
```

Derived directly from `x * y = k` — keeping the invariant constant ensures price is determined purely by supply and demand.

## The x \* y = k Formula

The constant product invariant is what makes the AMM work without an order book or external price feed. When a user swaps tokenA for tokenB:

```
Before: reserveA * reserveB = k
After:  (reserveA + amountIn) * (reserveB - amountOut) = k
```

Solving for `amountOut`:

```
amountOut = reserveOut * amountIn / (reserveIn + amountIn)
```

The price adjusts automatically — the more tokenB is bought, the less remains in the pool, and the more expensive each unit becomes.

## LP Token Design

The AMM contract inherits OpenZeppelin's ERC20, making the contract itself the LP token. This means:

- `_mint` and `_burn` are available without a separate token contract
- LP balances are queryable via `amm.balanceOf(address)`
- LP tokens are transferable — liquidity positions can be traded

## Security Considerations

- **CEI pattern**: state (reserves) updated after external calls in `removeLiquidity` — to be reviewed
- **Pending improvements**: events for `addLiquidity` and `removeLiquidity`, constructor validation for zero addresses and duplicate tokens, `getAmountOut` view function for frontends

## Tech Stack

- Solidity `^0.8.13`
- [Foundry](https://book.getfoundry.sh/) — build, test, deploy
- [OpenZeppelin](https://openzeppelin.com/contracts/) — ERC20, IERC20, Math

## Getting Started

```bash
git clone <repo>
cd amm
forge install
forge build
forge test -vv
```

## License

MIT
