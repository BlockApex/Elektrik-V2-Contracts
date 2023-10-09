// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {OrderEngine} from "./libraries/OrderEngine.sol";

contract AdvancedOrderEngine {
    using OrderEngine for OrderEngine.Order;

    function fillOrders(
        OrderEngine.Order[] calldata orders,
        uint256[] calldata clearingPrices,
        bytes calldata facilitatorInteractionCalldata,
        address facilitatorInteractionTargetContract
    ) external {
        // Perform sanity checks (for example, orders and clearing prices array must have same length, etc)
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
