// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

interface IQuoter {
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external payable returns(uint256);
}