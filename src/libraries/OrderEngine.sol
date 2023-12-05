// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

library OrderEngine {

    struct A {
        uint256 nonce;
        uint256 validTill;
        uint256 sellTokenAmount;
        uint256 buyTokenAmount;
        uint256 feeAmounts; // Optional
    }

    struct B {
        address maker;
        address operator; // Null on public orders
        address recipient;
        IERC20 sellToken;
        IERC20 buyToken;
    }

    struct C {
        bool isPartiallyFillable;
        bytes32 extraData;
        bytes predicateCalldata;
        bytes preInteraction;
        bytes postInteraction;
    }
    struct Order {
        A a;
        B b;
        C c;
    }

    bytes32 public constant ORDER_TYPE_HASH =
        keccak256(
            "Order("
            "A("
            "uint256 nonce,"
            "uint256 validTill,"
            "uint256 sellTokenAmount,"
            "uint256 buyTokenAmount,"
            "uint256 feeAmounts,"
            ")"
            "B("
            "address maker,"
            "address operator,"
            "address recipient,"
            "IERC20 sellToken,"
            "IERC20 buyToken,"
            ")"
            "C("
            "bool isPartiallyFillable,"
            "bytes32 extraData,"
            "bytes predicateCalldata,"
            "bytes preInteraction,"
            "bytes postInteraction"
            ")"
            ")"
        );

    function hash(Order calldata order) public pure returns (bytes32) {
        return (
            keccak256(
                abi.encode(
                    ORDER_TYPE_HASH,
                    A(
                        order.a.nonce,
                        order.a.validTill,
                        order.a.sellTokenAmount,
                        order.a.buyTokenAmount,
                        order.a.feeAmounts
                    ),
                    B(
                        order.b.maker,
                        order.b.operator,
                        order.b.recipient,
                        order.b.sellToken,
                        order.b.buyToken
                    ),
                    C(
                        order.c.isPartiallyFillable,
                        order.c.extraData,
                        abi.encodePacked(order.c.predicateCalldata),
                        abi.encodePacked(order.c.preInteraction),
                        abi.encodePacked(order.c.postInteraction)
                    )
                )
            )
        );
    }

    function isContract(Order calldata order) public view returns (bool) {
        return order.b.maker.code.length > 0;
    }
}
