// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {OrderEngine} from "./../libraries/OrderEngine.sol";
import {IFacilitatorInteractionNotificationReceiver} from "./../interfaces/IFacilitatorInteractionNotificationReceiver.sol";
import {console2} from "forge-std/Test.sol";

contract Helper is IFacilitatorInteractionNotificationReceiver {
    using SafeERC20 for IERC20;
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address operator = 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c;

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

        for (uint i = 0; i < borrowedTokens.length; i++) {

            interactionData = abi.encodeWithSelector(
                weth.transfer.selector,
                operator,
                borrowedAmounts[i]
            );

            (bool success, bytes memory data) = address(borrowedTokens[i]).call(interactionData);
            require (success);

            emit Swapped(
                OrderEngine.hash(orders[i]),
                orders[i].maker,
                address(borrowedTokens[i]),
                borrowedAmounts[i],
                interactionData,
                data
            );
        }


    }
}
