# Notes

- The permit feature is not present.
- The functionality of fee-on-transfer tokens is uncertain.
- The contract supports only ERC20-compatible tokens.
- Logging events at the end of functions; events are considered as an effect, so it deviates from the CEI pattern, but it doesn't pose a safety concern.
- Using two loops in the 'fillOrders' function because a single loop can't achieve the same result.
- If an order is created off-chain with the same configuration parameters, including nonce, the contract treats it as the same order and doesn't revert.
- Charging fee amounts separately on top of sell tokens, similar to COW swap, and transferring them to the fee collector's address.
- The contract only allows settling orders with both buy and sell tokens whitelisted.
- The contract is not utilizing OpenZeppelin v5.
- Expecting the facilitator to ensure that there are no duplicate addresses in the 'borrowedTokens' array to save gas.
