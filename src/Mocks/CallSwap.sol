// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IPreInteractionNotificationReceiver} from "./../interfaces/IPreInteractionNotificationReceiver.sol";
import {console2} from "forge-std/Test.sol";

contract Swapper is IPreInteractionNotificationReceiver {
    using SafeERC20 for IERC20;
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address swapRouter2 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    event Swapped(
        bytes32 orderHash,
        address maker,
        uint256 executedSellAmount,
        uint256 executedBuyAmount,
        uint256 filledSellAmount,
        bytes interactionData,
        bytes result
    );

    function fillOrderPreInteraction(
        bytes32 orderHash,
        address maker,
        uint256 executedSellAmount,
        uint256 executedBuyAmount,
        uint256 filledSellAmount,
        bytes memory interactionData
    ) external {

        console2.log("balance: ", weth.balanceOf(address(this)));
        weth.approve(swapRouter2, type(uint).max);
        (bool success, bytes memory data) = address(swapRouter2).call(interactionData);
        require (success);


        emit Swapped(
            orderHash,
            maker,
            executedSellAmount,
            executedBuyAmount,
            filledSellAmount,
            interactionData,
            data
        );
    }
}
