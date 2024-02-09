// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {OrderEngine} from "../libraries/OrderEngine.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/**
 * @notice Interface for facilitator interaction hook, it is invoked after funds are transferred from the 'maker' to the 'vault'.
 */
interface IFacilitatorInteractionNotificationReceiver {
    /**
     * @notice Callback method that gets called after funds transfer from the 'maker' to the 'vault'.
     * @param orders Orders the facilitator is willing to fill.
     * @param executedSellAmounts An array of sell token amounts requested by the facilitator from order makers.
     * @param executedBuyAmounts An array of buy token amounts offered by the facilitator to the makers.
     * @param borrowedTokens An array of token addresses the facilitator wants to borrow from the vault.
     * @param borrowedAmounts An array specifying the corresponding amounts of each token the facilitator wants to borrow.
     * @param interactionData Interaction calldata
     * @dev `executedSellAmounts` and `executedBuyAmounts` have to be divided by 1e18 since contract recieves them scaled upto 1e36
     */
    function fillOrderInteraction(
        OrderEngine.Order[] calldata orders,
        uint256[] calldata executedSellAmounts,
        uint256[] calldata executedBuyAmounts,
        IERC20[] calldata borrowedTokens,
        uint256[] calldata borrowedAmounts,
        bytes memory interactionData
    ) external;
}
