# Order Execution Flow

## Flow chart diagram

[View Flow Chart Diagram](https://miro.com/app/board/uXjVMi9rdBk=/?moveToWidget=3458764566051732586&cot=14)

## Order Execution Flow in the Smart Contract

1. **Transaction-Specific Sanity Checks**: The function begins by conducting initial checks to ensure the correctness of the transaction's calldata. For example, it verifies that the function is called with at least one order.

2. **Iteration Over Orders**: For each order in the transaction, the function performs the following:

   - **Order-Specific Sanity Checks**: These checks ensure that there are no issues with the order parameters, including verifying that the order has not expired.
   - **Predicate Verification**: The predicates specified by the maker are validated to confirm that all preconditions have been met and the order can be executed.
   - **Signature Verification**: The order's signature is checked to ensure it hasn't been tampered with.
   - **Pre-Interaction Hook**: If the maker has specified a pre-interaction hook, a low-level call is made to an arbitrary contract with calldata defined by the maker. Control flow is transferred to this contract to allow for custom actions. The control flow returns to the `AdvancedOrderEngine` contract once this hook completes.
   - **Asset Transfer to Vault**: Assets are transferred from the maker to the vault.

   _Note: After this iteration ends, the vault now holds all the sell tokens of the orders in this transaction._

3. **Facilitator Interaction**: Facilitators have the opportunity to interact with an arbitrary contract using arbitrary calldata. They can use the funds held in the vault (by requesting them first) to offer better execution prices to makers and for their own profit. This flexibility enables facilitators to offer improved execution prices to order makers and explore various profit strategies.

4. **Another Iteration Over Orders**: A second iteration begins with the goal of transferring buy tokens to the respective makers. The process includes:

   - **Price Verification**: Ensuring that the facilitator's solution offers at least the price requested by the maker.
   - **Asset Transfer to Maker**: Assets are transferred from the vault to the maker.
   - **Post-Interaction Hook**: If the maker has specified a post-interaction hook, a low-level call is made to an arbitrary contract with calldata defined by the maker. Control flow is transferred to this contract to allow for custom actions. The control flow returns to the `AdvancedOrderEngine` contract once this hook completes.
   - **Logging the Order Fill**: An event is logged to mark the successful execution of the order.

   _Note: Once this iteration is completed, the vault must not hold any tokens._

5. **Transaction Conclusion**: Once the second iteration ends, the transaction concludes.
