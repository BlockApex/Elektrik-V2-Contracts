// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/EIP712.sol";

library OrderEngine {
    struct Order {
        uint256 nonce;
        uint256 validTill;
        uint256 sellTokenAmount;
        uint256 buyTokenAmount;
        uint256 feeAmounts; // Optional
        address maker;
        address operator; // Null on public orders
        address recipient;
        IERC20 sellToken;
        IERC20 buyToken;
        bool isPartiallyFillable;
        bytes32 extraData;
        bytes predicateCalldata;
        bytes preInteraction;
        bytes postInteraction;
    }

    bytes32 public constant ORDER_TYPE_HASH =
        keccak256(
            "Order("
            "uint256 nonce,"
            "uint256 validTill,"
            "uint256 sellTokenAmount,"
            "uint256 buyTokenAmount,"
            "uint256 feeAmounts,"
            "address maker,"
            "address operator,"
            "address recipient,"
            "IERC20 sellToken,"
            "IERC20 buyToken,"
            "bool isPartiallyFillable,"
            "bytes32 extraData,"
            "bytes predicateCalldata,"
            "bytes preInteraction,"
            "bytes postInteraction"
            ")"
        );

    function hash(Order calldata order) public pure returns (bytes32) {
        return (
            keccak256(
                abi.encode(
                    ORDER_TYPE_HASH,
                    order.nonce,
                    order.validTill,
                    order.sellTokenAmount,
                    order.buyTokenAmount,
                    order.feeAmounts,
                    order.maker,
                    order.operator,
                    order.recipient,
                    order.sellToken,
                    order.buyToken,
                    order.isPartiallyFillable,
                    order.extraData,
                    keccak256(order.predicateCalldata),
                    keccak256(order.preInteraction),
                    keccak256(order.postInteraction)
                )
            )
        );
    }

    function hash(Order calldata order, bytes32 domainSeparator) public pure returns (bytes32) {
        return ECDSA.toTypedDataHash(domainSeparator, hash(order));
    }

    function encodeOrder(Order calldata order) public pure returns (bytes memory) {
        return (
            abi.encode(
                order.nonce,
                order.validTill,
                order.sellTokenAmount,
                order.buyTokenAmount,
                order.feeAmounts,
                order.maker,
                order.operator,
                order.recipient,
                order.sellToken,
                order.buyToken,
                order.isPartiallyFillable,
                order.extraData,
                keccak256(order.predicateCalldata),
                keccak256(order.preInteraction),
                keccak256(order.postInteraction)
            )
        );
    }

    function decodeOrder(bytes memory encodedOrder) public pure returns (Order memory) {
        (
            uint256 nonce,
            uint256 validTill,
            uint256 sellTokenAmount,
            uint256 buyTokenAmount,
            uint256 feeAmounts,
            address maker,
            address operator,
            address recipient,
            address sellTokenAddress,
            address buyTokenAddress,
            bool isPartiallyFillable,
            bytes32 extraData,
            bytes32 predicateCalldata,
            bytes32 preInteraction,
            bytes32 postInteraction
        ) = abi.decode(encodedOrder, (uint256, uint256, uint256, uint256, uint256, address, address, address, address, address, bool, bytes32, bytes32, bytes32, bytes32));

        // Assemble the decoded data into an Order struct
        Order memory order = Order({
            nonce: nonce,
            validTill: validTill,
            sellTokenAmount: sellTokenAmount,
            buyTokenAmount: buyTokenAmount,
            feeAmounts: feeAmounts,
            maker: maker,
            operator: operator,
            recipient: recipient,
            sellToken: IERC20(sellTokenAddress),
            buyToken: IERC20(buyTokenAddress),
            isPartiallyFillable: isPartiallyFillable,
            extraData: extraData,
            predicateCalldata: abi.encodePacked(predicateCalldata),
            preInteraction: abi.encodePacked(preInteraction),
            postInteraction: abi.encodePacked(postInteraction)
        });

        return order;
    }

    function isContract(Order calldata order) public view returns (bool) {
        return order.maker.code.length > 0;
    }
}
