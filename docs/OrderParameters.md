# Order Parameters and Configuration

When creating a limit order on Elektrik Limit Order Protocol, users can configure various parameters. These parameters define the order's characteristics and behavior, offering a highly versatile experience. Here are the components available for user configuration when creating a limit order on the Elektrik Limit Order Protocol:

1. `nonce`: Users can assign a unique number to distinguish the order.

2. `validTill`: Users can set an expiration time for the order, after which it becomes invalid.

3. `sellTokenAmount`: The quantity of the sell token the user wants to offer in the order.

4. `buyTokenAmount`: The desired quantity of the buy token.

5. `feeAmounts` (Optional): The fee that the order maker is willing to pay, given priority when the order is filled.

6. `maker`: The address from which funds will be transferred to the vault.

7. `operator`: This field is used for making orders private. Null address means order is public.

8. `recipient`: This is the address where the buy tokens will be received upon order execution. If makers want to receive funds at the maker's address, set this field to the maker's address.

9. `sellToken`: The token the user is willing to sell in the order.

10. `buyToken`: The token the user desires to purchase.

11. `isPartiallyFillable`: Users can choose whether the order can be partially filled or must be executed in full.

12. `extraData`: Any data useful for off-chain calculation when an order is filled

13. `predicates`: Makers can specify any number of arbitrary static calls, which determine whether an order can be executed. This feature can be utilized for various purposes, including stop loss or take profit orders.

14. `preInteraction`: This callback function gets called right before funds are transferred from the maker to the vault. The maker can use it for various purposes, such as unstaking sell tokens.

15. `postInteraction`: This callback function gets called right after funds are transferred to the maker from the vault. The maker can use it for various purposes, such as staking buy tokens.
