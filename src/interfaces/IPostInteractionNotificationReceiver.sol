// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @notice Interface for maker post-interaction hook, it is invoked after funds are transferred from the 'vault' to the 'maker'.
 */
interface IPostInteractionNotificationReceiver {
    /**
     * @notice Callback method that gets called after all funds transfers
     * @param orderHash Hash of the order being processed
     * @param maker Maker address
     * @param clearingPrice Actual amount maker will receive
     * @param interactionData Interaction calldata
     */
    function fillOrderPostInteraction(
        bytes32 orderHash,
        address maker,
        uint256 clearingPrice,
        bytes memory interactionData
    ) external;
}
