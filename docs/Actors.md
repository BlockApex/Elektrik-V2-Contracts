# Actors

In our protocol, there are four key actors, each playing a distinct role in the operation of the Elektrik Limit Order Protocol. Below are the descriptions of these actors and their roles within the system:

## Order Makers
Users who place limit orders on Elektrik DEX are referred to as order makers. They do so by signing a message that specifies various parameters, including buy and sell tokens, along with their respective amounts. This signed message is then utilized to create limit orders on Elektrik DEX.

## Facilitators
Facilitators play a critical role in the order fulfillment process on Elektrik DEX. They retrieve all the orders from the Elektrik order book and propose solutions that allow for the execution of multiple orders in a transaction, either in full or partially. Facilitators have a wide range of methods at their disposal to fill orders in a transaction, such as utilizing Coincidence of Wants (COWs). They achieve this by finding one or more orders where the buy token and its quantity match one or more sell orders' tokens and their corresponding amounts.

If facilitators prefer to solely utilize COWs in their solution, they can specify no facilitator interaction. Facilitators also have the option to engage in swaps with other DEXes during their interactions. Notably, during their interaction, facilitators gain access to all the funds stored in the vault, akin to a flash loan with no interest. This expanded access enables facilitators to explore various strategies aimed at offering more favorable execution prices to the makers while also earning a profit for themselves.

Facilitators are expected to propose their solutions by submitting orders that can be executed within the current transaction, specifying the amounts they are willing to offer for each order. Importantly, facilitators are responsible for transferring the committed funds they offer to the makers back to the vault at the conclusion of their interaction.

## Operator
These are privileged users, whitelisted by the owner of the contract. They receive solutions proposed by facilitators. They are expected to choose the solution that offers the best execution price to the makers and subsequently invoke the ```fillOrders``` function with the chosen solution.

## Owner
The owner of the smart contract holds the authority to grant or revoke operator access. By default, the deployer of the smart contract is vested with the role of owner.


