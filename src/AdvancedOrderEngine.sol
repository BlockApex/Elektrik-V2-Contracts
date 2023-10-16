// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {EIP712, ECDSA} from "openzeppelin/utils/cryptography/EIP712.sol";
import {IERC1271} from "openzeppelin/interfaces/IERC1271.sol";
import {OrderEngine} from "./libraries/OrderEngine.sol";
import {IPreInteractionNotificationReceiver} from "./interfaces/IPreInteractionNotificationReceiver.sol";
import {IPostInteractionNotificationReceiver} from "./interfaces/IPostInteractionNotificationReceiver.sol";

import {IInteractionNotificationReceiver} from "./interfaces/IInteractionNotificationReceiver.sol";

import {Decoder} from "./libraries/Decoder.sol";
import "./AdvancedOrderEngineErrors.sol";
import {Vault} from "./Vault.sol";

contract AdvancedOrderEngine is Vault, EIP712 {
    using OrderEngine for OrderEngine.Order;
    using Decoder for bytes;

    // @notice Stores unfilled amounts for each order.
    // TBD: public or private?
    mapping(bytes32 => uint256) public remainingFillableAmount;

    event OrderFill(
        address operator,
        address maker,
        bytes32 orderHash,
        uint256 offeredAmount
    );

    constructor(
        string memory name,
        string memory version
    ) EIP712(name, version) {}

    /**
     * @notice Fills multiple orders by processing the specified orders and clearing prices.
     *
     * @param orders An array of order structs representing the orders to be filled.
     * @param offeredAmounts An array of clearing prices that the facilitator is offering to the makers.
     * @param facilitatorInteraction The calldata for the facilitator's interaction.
     */
    function fillOrders(
        OrderEngine.Order[] calldata orders,
        uint256[] calldata offeredAmounts,
        bytes[] calldata signatures,
        bytes calldata facilitatorInteraction
    ) external {
        // STUB: ONLY OPERATOR //

        // TBD: max array length check needed? Considering fn will be restricted to operators only

        /** 
            TBD: no need to check for offeredAmounts length to be equal to 0 as if that's the case, txn will revert in subsequent check
            but should we check for offeredAmounts length to be equal to zero explicitly for better error reporting? 
            Also consider generic error message
        */
        // Revert if the orders array length is zero.
        if (orders.length == 0) {
            revert EmptyOrdersArray();
        }

        // Revert if the length of the orders array does not match the clearing prices array.
        if (orders.length != offeredAmounts.length) {
            revert ArraysLengthMismatch(orders.length, offeredAmounts.length);
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

            // STUB: PARTIAL FILL FEATURE //

            // TBD: debatable, can take signing scheme in order schema or can verify like 1inch
            if (order.isContract()) {
                if (
                    !(IERC1271(order.maker).isValidSignature(
                        orderMessageHash,
                        signature
                    ) == IERC1271.isValidSignature.selector)
                ) {
                    revert BadSignature();
                }
            } else {
                address signer = ECDSA.recover(orderMessageHash, signature);
                if (signer != order.maker) {
                    revert BadSignature();
                }
            }

            // STUB: VERIFY PREDICATES //

            if (order.preInteraction.length >= 20) {
                // proceed only if interaction length is enough to store address
                (
                    address interactionTarget,
                    bytes calldata interactionData
                ) = order.preInteraction.decodeTargetAndCalldata();
                IPreInteractionNotificationReceiver(interactionTarget)
                    .fillOrderPreInteraction(
                        orderMessageHash,
                        order.maker,
                        offeredAmounts[i],
                        interactionData
                    );
            }

            // TODO: reorder params type
            _receiveAsset(order.sellToken, order.sellTokenAmount, order.maker);

            unchecked {
                ++i;
            }
        }

        if (facilitatorInteraction.length >= 20) {
            // proceed only if interaction length is enough to store address
            (
                address interactionTarget,
                bytes calldata interactionData
            ) = facilitatorInteraction.decodeTargetAndCalldata();
            IInteractionNotificationReceiver(interactionTarget)
                .fillOrderInteraction(
                    msg.sender,
                    orders,
                    offeredAmounts,
                    interactionData
                );
        }

        // TODO: Need optimization
        for (uint256 i; i < orders.length; ) {
            OrderEngine.Order calldata order = orders[i];

            bytes32 orderHash = order.hash();
            bytes32 orderMessageHash = _hashTypedDataV4(orderHash);

            if (order.buyTokenAmount > offeredAmounts[i]) {
                revert LimitPriceNotRespected(
                    order.buyTokenAmount,
                    offeredAmounts[i]
                );
            }

            // TODO: reorder params type
            _sendAsset(order.buyToken, offeredAmounts[i], order.maker);

            if (order.postInteraction.length >= 20) {
                // proceed only if interaction length is enough to store address
                (
                    address interactionTarget,
                    bytes calldata interactionData
                ) = order.postInteraction.decodeTargetAndCalldata();
                IPostInteractionNotificationReceiver(interactionTarget)
                    .fillOrderPostInteraction(
                        orderMessageHash,
                        order.maker,
                        offeredAmounts[i],
                        interactionData
                    );
            }

            // TODO: decide where to emit event, as its considered as an effect so maybe do it somewhere in the start; what params to log;
            // events spam? ; consider emitting just one event
            emit OrderFill(
                msg.sender,
                order.maker,
                orderMessageHash,
                offeredAmounts[i]
            );

            unchecked {
                ++i;
            }
        }
    }
}
