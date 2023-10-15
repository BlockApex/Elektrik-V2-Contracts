// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

error ArraysLengthMismatch(uint256 ordersArrLen, uint256 clearingPricesArrLen);
error ZeroFacilitatorTargetAddress();
error EmptyOrdersArray();
error OrderExpired(bytes32 orderHash);
error ZeroTokenAmounts();
error ZeroAddress();
error BadSignature();
