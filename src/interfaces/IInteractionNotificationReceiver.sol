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

    function getTokenAddressesAndAmounts(
        address operator,
        OrderEngine.Order[] calldata orders,
        uint256[] calldata offeredAmounts
    ) external pure returns (address[] memory, uint256[] memory, address); // TBD: pure cause assuming facilitator will extract tokens and amounts to withdraw from vault from fn params/ calldata
}
