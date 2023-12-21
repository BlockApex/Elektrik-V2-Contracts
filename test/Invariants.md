| **Property**                                                                                                    | **Type**              | **Risk**| **Tested (✔/✘)**|
| ------------------------------------------------------------------------------------------------------------ | ----------------- | ---- | ------ |
| All orders must be fulfilled/executed. / revert condition.                                                   | High-Level        |      |        |
| Fill order must be only called by Operator.                                                                  | High-Level        |      |        |
| All orders must be fulfilled at a specified price.                                                           | High-Level        |      |        |
| Facilitator interactions must not result in loss of funds.                                                   |                   |      |        |
| An order from a Contract must be fulfilled.                                                                  | Unit-test         |      |        |
| An order from an EOA must be fulfilled.                                                                      | Unit-test         |      |        |
| Maker should be able to cancel an order.                                                                     | Unit-test         |      |        |
| After the matching of the orders, the balance must be updated rightly. / transfer of funds must be done.     |                   |      |        |
| The vault must not keep funds after the fullfilment of orders. I.e balance[before] == balance[after]         |                   |      |        |
| The assets from maker to taker must be transferred without any cutting of fees (right Now).                  |                   |      |        |
| If applied , The private orders must only be fulfilled by the specified entity                               |                   |      |        |
| The Order Engine must operate on erc20 assets                                                                |                   |      |        |
| If falsh-loan facility is leveraged by facilitator , funds should be returned within the tx                  |                   |      |        |
| Upon filling orders funds from Seller & Maker are moved to vault                                             | State Transitions |      |        |
| Upon Finalizing the order funds are moved from vault to seller and maker                                     | State Transitions |      |        |
| Only Whitelisted tokens to be accepted                                                                       |                   |      |        |
| Funds should not be lost in case the receiver is zero address                                                |                   |      |        |
| After the expiry time the order should not be fullfilled                                                     |                   |      |        |
| 1 Large order should fullfil multiple small orders                                                           | High-Level        |      |        |
| Orders with higher priority ( higher fees) should always be processed before lower priority orders           | High-Level        |      |        |
| Facilitator interactions must be in scope of order fulfillment within a transaction                          |                   |      |        |
| once an order is cancelted it cant be executed , even partially                                              |                   |      |        |
| the contract should handle unexpected input like large arrays without failing or causing excessive gas costs |                   |      |        |
