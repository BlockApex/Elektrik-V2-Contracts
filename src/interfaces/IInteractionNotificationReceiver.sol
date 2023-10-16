// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @notice Interface for facilitator interaction hook, it is invoked after funds are transferred from the 'maker' to the 'vault'.
 */
interface IInteractionNotificationReceiver {
    /**
     * @notice Callback method that gets called after funds transfer from the 'maker' to the 'vault
     * @param operator Address of the caller who executed orders on behalf of the facilitator.
     * @param maker Address of the oorder maker
     * @param orderSellAmount Amount of the asset the maker is willing to sell.
     * @param amountOffered Amount of the asset the facilitator is willing to pay in exchange for the sell amount.
     * @param interactionData Interaction calldata
     */
    function fillOrderInteraction(
        address operator,
        address maker,
        uint256 orderSellAmount,
        uint256 amountOffered,
        bytes memory interactionData
    ) external;
}
