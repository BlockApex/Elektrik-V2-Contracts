# Design Justifications

1. **Separate Interfaces for Pre and Post Interaction Hooks:**
   - Separate interfaces for pre and post interaction hooks were implemented despite having the same function definition. This design choice allows users to execute distinct logic for both the pre-interaction and post-interaction hooks without the need to have distinct contracts for both interactions.

2. **Dynamic Executed Buy Amounts from Facilitator:**
   - Initially, there was consideration for allowing facilitators to specify executed buy amounts during their interaction. However, this approach was discarded to prevent potential manipulation during simulation, where the facilitator could offer better prices and then modify the amounts in the interaction. While a check was possible to address this, it was skipped due to additional gas costs.

3. **No Check on Max Array Length:**
   - The decision was made not to implement a check on the maximum array length for function parameters. This choice was driven by considerations such as potential deployment on multiple chains, where the maximum array length could vary due to different block gas limits. Since these arrays are parameters and not state arrays, and the function iterates over them without storing them in state arrays, there is no risk of denial-of-service (DoS) attacks. 

5. **Cancellation Order Handling:**
   - Rather than making the signature invalid in the event of order cancellation, the decision was made to use the sell amount as the filled sell amount to accommodate the partial order fills feature.

6. **Borrowed Token and Amounts in Function Params:**
   - To save gas and simplify facilitator interactions, the approach is to ask for borrowed token addresses and amounts in function parameters. This avoids the need for an additional call to a facilitator interaction getter function. Transferring maker sell tokens directly to the facilitator was considered but raised complications, including the need for facilitator approval and the potential conflict with facilitators not wanting to receive funds at their address.

7. **Non-Enforcement of Facilitator Returning Borrowed Amounts:**
   - Chose not to add a check to ensure facilitators have given back borrowed amounts, mainly to avoid extra gas costs. Since the contract has already ensured that what the facilitator offered respects the maker's limit price, and we are transferring what the facilitator promised from the vault to the maker, the transaction will revert if the facilitator backs off from its commitment.


