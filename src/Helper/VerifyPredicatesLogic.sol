// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {IPredicates} from ".././interfaces/IPredicates.sol";
import "forge-std/console.sol";

contract VerifyPredicatesLogic {
    error PredicateIsNotTrue();

    address public predicateContract;

    constructor(address _predicateContract) {
        predicateContract = _predicateContract;
    }

    function checkPredicate(
        bytes calldata predicate
    ) public view returns (bool) {
        (bool success, uint256 res) = IPredicates(predicateContract)
            .staticcallForUint(predicateContract, predicate);
        return success && res == 1;
    }

    function verify(bytes calldata predicates) external view {
        if (predicates.length > 0) {
            if (!checkPredicate(predicates)) revert PredicateIsNotTrue();
        }
    }
}
