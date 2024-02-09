# Test Summary

| Test Name                  | Description                                                                      | Tested (✔/✘)    |
|--------------------------- |----------------------------------------------------------------------------------|------------------|
| `setUp`                     | Initializes the smart contract with predefined conditions for subsequent tests. | ✔               |
| `testWithdraw`               | Validates the withdrawal functionality of the smart contract, including invalid attempts, ownership checks, and successful withdrawal. | ✔               |
| `testOperatorPrivilege`      | Tests the management of operator privileges in the smart contract, covering operator addition, removal, ownership checks, and invalid attempts. | ✔               |
| `testUpdateTokenWhitelist`   | Checks the token whitelist updating functionality of the smart contract, including token whitelisting, invalid attempts, and ownership checks. | ✔               |
| `testChangePredicateAddress` | Validates the functionality of changing the predicate address, covering successful address change, invalid attempts, and ownership checks. | ✔               |
| `testChangeFeeCollectorAddress` | Checks the functionality of changing the fee collector address, covering successful address change, invalid attempts, and ownership checks. | ✔               |
| `testFillOrders`             | Tests the order filling functionality of the smart contract, including successful order filling with updated token balances. | ✔               |
| `testRingOrders`             | Validates the order ring functionality of the smart contract, ensuring correct token balances after ring execution. | ✔               |
| `testFillOrderInChunks`      | Tests the order filling functionality in chunks, covering multiple order fillings with updated token balances. | ✔               |
| `testNoOrderInputFillOrders` | Ensures the smart contract reverts when attempting to fill orders with no input orders provided. | ✔               |
| `testInvalidInputFillOrders` | Validates the handling of invalid inputs during the order filling process, including expired orders, zero amounts, non-whitelisted tokens, zero address tokens/operators, and invalid signatures. | ✔               |
| `testOrderReplay`            | Checks that the smart contract reverts when attempting to replay an already filled order. | ✔               |
| `testInputLengthMismatchFillOrders` | Validates that the smart contract reverts when encountering input length mismatches during the order filling process. | ✔               |
| `testPartiallyFillableOrder`  | Tests the partially fillable order functionality, ensuring correct token balances after partially filling orders. | ✔               |
| `testExceedsOrderSellAmount`  | Ensures the smart contract reverts when attempting to fill orders with amounts exceeding the order's sell amount. | ✔               |
| `testPartiallyFillableOrderFail` | Tests the failure scenario when attempting to fill partially fillable orders with incorrect sell and buy amounts. | ✔ |
| `testInvalidSignature` | Tests the failure scenario when attempting to fill orders with an invalid signature. | ✔ |
| `testFillOrKillFail` | Tests the failure scenario when attempting to fill orders with the "FillOrKill" condition not met. | ✔ |
| `testPredicateFail` | Tests the failure scenario when executing orders with a predicate that evaluates to false. | ✔ |
| `testMultiplePredicateOR` | Tests the successful execution of orders with a logical OR combination of multiple predicates, involving 'lt' and 'gt' conditions. | ✔ |
| `testMultiplePredicateOR1` | Tests the successful execution of orders with another combination of logical OR of multiple predicates, involving 'lt' conditions. | ✔ |
| `testMultiplePredicateORFail` | Tests the failure scenario when executing orders with a logical OR combination of multiple predicates, where the arbitrary call in the second predicate fails. | ✔ |
| `testMultiplePredicateANDFail` | Tests the failure scenario when executing orders with a logical AND combination of multiple predicates, where the arbitrary call in the second predicate fails. | ✔ |
| `testMultiplePredicateANDFail1` | Tests another failure scenario when executing orders with a logical AND combination of multiple predicates, where the arbitrary call in the first predicate fails. | ✔ |
| `testMultiplePredicateAND` | Tests the successful execution of orders with a logical AND combination of multiple predicates, involving 'lt' conditions. | ✔ |
| `testPredicate` | Tests the successful execution of orders with a single predicate involving 'lt' conditions. | ✔ |
| `testDrain`                    | Execute drain functionality with various orders. | ✔                  |
| `testDrainERC20`               | Test ERC20 drain functionality, checking for same buy and sell tokens. | ✔                  |
| `testAsymetricFillOrKillOrders` | Test asymmetrical fill or kill orders.         | ✔                  |
| `testAsymetricPartiallyFillOrders` | Test asymmetrical partially filled orders.  | ✔                  |
| `testFacilitatorBorrowedAmounts` | Test facilitator borrowed amounts functionality. | ✔                  |
| `testCancelOrders`              | Tests order cancellation with successful fill        | ✔                   |
| `testCancelOrdersFail`          | Tests order cancellation with failed fill when order already filled, invalid access.          | ✔                   |
| `testSingleOrder`               | Tests onchain dex swap through pre-interaction     | ✔                   |
| `testFacilitatorSwap`           | Tests onchain dex swap through facilitator interaction                 | ✔                   |