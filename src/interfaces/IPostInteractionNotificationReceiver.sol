// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @notice Interface for maker post-interaction hook, it is invoked after funds are transferred from the 'vault' to the 'maker'.
 */
interface IPostInteractionNotificationReceiver {
    /**
     * @notice Callback method that gets called before any funds transfers
     * @param orderHash Hash of the order being processed
     * @param maker Address of the order maker.
     * @param executedSellAmount Sell token amount requested by the facilitator from order maker.
     * @param executedBuyAmount Buy token amount offered by the facilitator to the maker.
     * @param interactionData Interaction calldata
     */
    function fillOrderPostInteraction(
        bytes32 orderHash,
        address maker,
        uint256 executedSellAmount,
        uint256 executedBuyAmount,
        bytes memory interactionData
    ) external;
}
