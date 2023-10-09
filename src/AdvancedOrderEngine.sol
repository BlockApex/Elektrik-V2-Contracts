// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {OrderEngine} from "./libraries/OrderEngine.sol";

contract AdvancedOrderEngine {
    using OrderEngine for OrderEngine.Order;

    function fillOrders() external {}
}
