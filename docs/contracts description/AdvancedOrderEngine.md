# AdvancedOrderEngine Contract

The `AdvancedOrderEngine` contract is a core contract of the Elektrik Limit Order Protocol, responsible for executing multiple orders within a single transaction.

## Flow chart diagram

[View Flow Chart Diagram](https://miro.com/app/board/uXjVMi9rdBk=/?moveToWidget=3458764566051732586&cot=14)

## Modifiers

### `onlyOperators`

The `onlyOperators` modifier restricts function calls to designated operator addresses, which are whitelisted by the contract owner.

## Functions

### `constructor`

The constructor function for this contract accepts two parameters: `name` and `version` of the domain separator. This ensures that all orders are valid within a specific context.

### `manageOperatorPrivilege`

This function is exclusively accessible to the contract owner. It allows the owner to grant or revoke operator privileges, thus controlling who can call the `fillOrders` function.

### `fillOrders`

The fillOrders function is a core function of the Elektrik Limit Order Protocol, enabling operators to execute multiple orders in a single transaction by utilizing a solution, which is ideally an optimal one, proposed by a facilitator. Here's an overview of the process:

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
