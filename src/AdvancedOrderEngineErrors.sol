// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

error ArraysLengthMismatch();
error ZeroFacilitatorTargetAddress();
error EmptyOrdersArray();
error OrderExpired(bytes32 orderHash);
error ZeroAmount();
error ZeroAddress();
error InvalidSignature();
error IncorrectDataLength();
error LimitPriceNotRespected();
error NotAnOperator(address caller);
error PredicateIsNotTrue();
error ExceedsOrderSellAmount();
error SamePredicateAddress();
error AccessStatusUnchanged();
error PrivateOrder();
error OrderFilledAlready();
error InvalidInteractionTarget();
error AccessDenied();
