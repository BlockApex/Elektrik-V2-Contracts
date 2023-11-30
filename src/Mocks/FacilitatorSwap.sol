// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {OrderEngine} from "./../libraries/OrderEngine.sol";
import {IFacilitatorInteractionNotificationReceiver} from "./../interfaces/IFacilitatorInteractionNotificationReceiver.sol";
import {console2} from "forge-std/Test.sol";

contract FacilitatorSwap is IFacilitatorInteractionNotificationReceiver {
    using SafeERC20 for IERC20;
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address swapRouter2 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    event Swapped(
        bytes32 orderHash,
        address maker,
        address executedSellAmount,
        uint256 executedBuyAmount,
        bytes interactionData,
        bytes result
    );

    function fillOrderInteraction(
        OrderEngine.Order[] calldata orders,
        uint256[] calldata,
        uint256[] calldata,
        IERC20[] calldata borrowedTokens,
        uint256[] calldata borrowedAmounts,
        bytes memory interactionData
    ) external {
        (bool success, bytes memory data) = address(swapRouter2).call(interactionData);
        require (success);

        emit Swapped(
            OrderEngine.hash(orders[0]),
            orders[0].maker,
            address(borrowedTokens[0]),
            borrowedAmounts[0],
            interactionData,
            data
        );
    }   

    function approve(
        address token,
        address to,
        uint256 amount
    ) external {
        IERC20(token).approve(to, amount);
    }   

    function updateRouter(
        address newRouter
    ) external {
        swapRouter2 = newRouter;
    }   
}
