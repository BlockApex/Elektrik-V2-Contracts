// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/console.sol";
import "forge-std/Test.sol";
import "forge-std/StdCheats.sol";
import "forge-std/Vm.sol";


contract TargetContract {

    function dummyFn(uint256 x) public pure returns (uint256) {
        return x;
    }

    function dummyFn1() public pure returns (uint256) {
        return 7;
    }

    function dummyFn2() public pure returns (uint256) {
        return 18;
    }
    
    function dummyFn3() public pure returns (uint256) {
        return 7;
    }

    function dummyBool() public pure returns (bool){
        return false;
    }


}
