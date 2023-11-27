// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IPriceFeed {
    function latestAnswer() external payable returns(uint256);
}