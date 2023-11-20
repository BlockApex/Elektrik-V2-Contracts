// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPredicates {
    function staticcallForUint(
        address target,
        bytes calldata data
    ) external view returns (bool success, uint256 res);
}
