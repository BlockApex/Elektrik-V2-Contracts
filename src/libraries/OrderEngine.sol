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
        address recipient; // TODO: maybe use null to represent msg.sender?
        address sellToken;
        address buyToken;
        bool isPartiallyFillable;
        bytes32 extraData;
        bytes predicates;
        bytes preInteraction;
        bytes postInteraction;
        bytes signature;
    }
}
