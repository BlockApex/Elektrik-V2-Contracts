// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library OrderEngine {
    // TODO: pack struct
    // TODO; signing scheme required?
    struct Order {
        uint256 nonce;
        uint256 validTill;
        uint256 sellTokenAmount; // TODO: see if smaller data type could be used
        uint256 buyTokenAmount; // TODO: see if smaller data type could be used
        uint256 feeAmounts;
        address maker;
        address taker; // null on public orders
        address recipient; // TBD: use null to represent maker? Right now expecting explicit address set
        address sellToken;
        address buyToken;
        bool isPartiallyFillable;
        bytes32 extraData;
        bytes predicates;
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
            "address taker,"
            "address recipient,"
            "address sellToken,"
            "address buyToken,"
            "bool isPartiallyFillable,"
            "bytes32 extraData,"
            "bytes predicates,"
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
                    order.taker,
                    order.recipient,
                    order.sellToken,
                    order.buyToken,
                    order.isPartiallyFillable,
                    order.extraData,
                    keccak256(order.predicates),
                    keccak256(order.preInteraction),
                    keccak256(order.postInteraction)
                )
            )
        );
    }

    function isContract(Order calldata order) public view returns (bool) {
        return order.maker.code.length > 0;
    }
}
