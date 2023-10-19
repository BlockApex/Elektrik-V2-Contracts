// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {OrderEngine} from "../libraries/OrderEngine.sol";

/**
 * @notice Interface for facilitator interaction hook, it is invoked after funds are transferred from the 'maker' to the 'vault'.
 */
interface IInteractionNotificationReceiver {
    /**
     * @notice Callback method that gets called after funds transfer from the 'maker' to the 'vault'.
     * @param operator Address of the caller who executed orders on behalf of the facilitator.
     * @param orders Orders the facilitator is willing to fill.
     * @param offeredAmounts Amounts of the asset the facilitator is offering to the makers.
     * @param interactionData Interaction calldata
     */
    function fillOrderInteraction(
        address operator,
        OrderEngine.Order[] calldata orders,
        uint256[] calldata offeredAmounts,
        bytes memory interactionData
    ) external;

    /**
     * @notice To retrieve token transfer details for a facilitator. 
     * @param operator Address of the caller who executed orders on behalf of the facilitator.
     * @param orders Orders the facilitator is willing to fill.
     * @param offeredAmounts Amounts of the asset the facilitator is offering to the makers.

     * @return tokenAddresses An array of token addresses that the facilitator wants from vault.
     * @return tokenAmounts An array specifying the corresponding amounts of each token to be transferred.
     * @return assetsRecipient The address at which the facilitator wants to receive the requested tokens.
     */
    function getFacilitatorTokenTransferDetails(
        address operator,
        OrderEngine.Order[] calldata orders,
        uint256[] calldata offeredAmounts
    )
        external
        pure
        returns (
            address[] memory tokenAddresses,
            uint256[] memory tokenAmounts,
            address assetsRecipient
        ); // TBD: pure cause assuming facilitator will extract tokens and amounts to withdraw from vault from fn params/ calldata, should we make it view?
}
