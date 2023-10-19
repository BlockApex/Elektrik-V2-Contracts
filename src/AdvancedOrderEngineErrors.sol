// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

error ArraysLengthMismatch();
error ZeroFacilitatorTargetAddress();
error EmptyOrdersArray();
error OrderExpired(bytes32 orderHash);
error ZeroTokenAmounts();
error ZeroAddress();
error BadSignature();
error IncorrectDataLength();
error LimitPriceNotRespected(uint256 desiredAmount, uint256 offeredAmount);
error NotAnOperator(address caller);
