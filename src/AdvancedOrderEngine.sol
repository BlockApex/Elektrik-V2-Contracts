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
    ) external {}
}
