// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {EIP712} from "openzeppelin/utils/cryptography/EIP712.sol";
import {IERC1271} from "openzeppelin/interfaces/IERC1271.sol";
import {OrderEngine} from "./libraries/OrderEngine.sol";
import "./AdvancedOrderEngineErrors.sol";

contract AdvancedOrderEngine is EIP712 {
    using OrderEngine for OrderEngine.Order;

    constructor(
        string memory name,
        string memory version
    ) EIP712(name, version) {}

    /**
     * @notice Fills multiple orders by processing the specified orders and clearing prices.
     *
     * @param orders An array of order structs representing the orders to be filled.
     * @param clearingPrices An array of clearing prices that the facilitator is offering to the makers.
     * @param facilitatorInteractionCalldata The calldata for the facilitator's interaction.
     * @param facilitatorInteractionTargetContract The address of the facilitator's target contract.
     */
    function fillOrders(
        OrderEngine.Order[] calldata orders,
        uint256[] calldata clearingPrices,
        bytes[] calldata signatures,
        bytes calldata facilitatorInteractionCalldata,
        address facilitatorInteractionTargetContract
    ) external {
        // TBD: max array length check needed? Considering fn will be restricted to operators only

        /** 
            TBD: no need to check for clearingPrices length to be equal to 0 as if that's the case, txn will revert in subsequent check
            but should we check for clearingPrices length to be equal to zero explicitly for better error reporting? 
            Also consider generic error message
        */
        // Revert if the orders array length is zero.
        if (orders.length == 0) {
            revert EmptyOrdersArray();
        }

        // Revert if the length of the orders array does not match the clearing prices array.
        if (orders.length != clearingPrices.length) {
            revert ArraysLengthMismatch(orders.length, clearingPrices.length);
        }

        // Revert if the facilitator has provided calldata for its interaction but has provided null target contract address.
        if (
            facilitatorInteractionCalldata.length != 0 &&
            facilitatorInteractionTargetContract == address(0)
        ) {
            revert ZeroFacilitatorTargetAddress(); // TBD: use generic error message i.e. ZeroAddress()
        }

        for (uint256 i; i < orders.length; ) {
            OrderEngine.Order calldata order = orders[i];
            bytes calldata signature = signatures[i];

            bytes32 orderHash = order.hash();
            bytes32 orderMessageHash = _hashTypedDataV4(orderHash);

            if (block.timestamp > order.validTill) {
                revert OrderExpired(orderHash);
            }

            if (order.buyTokenAmount == 0 || order.sellTokenAmount == 0) {
                revert ZeroTokenAmounts();
            }

            if (
                order.maker == address(0) ||
                order.buyToken == address(0) ||
                order.sellToken == address(0)
            ) {
                revert ZeroAddress();
            }

            unchecked {
                ++i;
            }
        }

        // Loop start
        // Perform order specific sanity checks
        // Verify signatjures
        // Verify predicates
        // Call pre-interaction hook
        // Transfer funds from maker to vault
        // Loop end
        // Call facilitator interaction
        // Loop start
        // Ensure facilitator is respecting maker price
        // Transfer funds from vault to maker
        // Call post-interaction hook
        // Emit event (decide where to emit event, as its considered as an effect so maybe do it somewhere in the start)
    }
}
