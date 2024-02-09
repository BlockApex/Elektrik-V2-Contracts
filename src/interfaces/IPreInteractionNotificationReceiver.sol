// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @notice Interface for maker pre-interaction hook, it is invoked before funds are transferred from the 'maker' to the 'vault'.
 */
interface IPreInteractionNotificationReceiver {
    /**
     * @notice Callback method that gets called before any funds transfers
     * @param orderHash Hash of the order being processed
     * @param maker Address of the order maker.
     * @param executedSellAmount Sell token amount requested by the facilitator from order maker.
     * @param executedBuyAmount Buy token amount offered by the facilitator to the maker.
     * @param filledSellAmount Amount of sell tokens that would be filled after this transaction is completed.
     * @param interactionData Interaction calldata
     * @dev `executedSellAmounts` & `executedBuyAmounts` DO NOT have to be scaled down by 1e18
     */
    function fillOrderPreInteraction(
        bytes32 orderHash,
        address maker,
        uint256 executedSellAmount,
        uint256 executedBuyAmount,
        uint256 filledSellAmount,
        bytes memory interactionData
    ) external;
}
