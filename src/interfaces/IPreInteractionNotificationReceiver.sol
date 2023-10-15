// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

/**
 * @notice Interface for maker pre-interaction hook, it is invoked before funds are transferred from the 'maker' to the 'vault'.
 */
interface IPreInteractionNotificationReceiver {
    /**
     * @notice Callback method that gets called before any funds transfers
     * @param orderHash Hash of the order being processed
     * @param maker Maker address
     * @param clearingPrice Actual amount maker will receive
     * @param interactionData Interaction calldata
     */
    function fillOrderPreInteraction(
        bytes32 orderHash,
        address maker,
        uint256 clearingPrice,
        bytes memory interactionData
    ) external;
}
