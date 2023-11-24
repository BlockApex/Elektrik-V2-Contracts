// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../../src/Helper/VerifyPredicatesLogic.sol";
import "../../../src/Predicates.sol";
import "../../../src/Helper/GenerateCalldata.sol";
import "../../../src/Helper/TargetContract.sol";

contract VerifyPredicatesLogicTest is Test {
    VerifyPredicatesLogic public verifyPredicate;
    TargetContract public targetContract;
    GenerateCalldata public generateCalldata;
    Predicates public predicateContract;

    function setUp() public {
        predicateContract = new Predicates();
        verifyPredicate = new VerifyPredicatesLogic(address(predicateContract));
        targetContract = new TargetContract();
        generateCalldata = new GenerateCalldata(address(targetContract));
    }
    /*
        To test

        1. Lt [x]
        2. Gt [x]
        3. and [x]
        4. or [x]
        5. not [x]
        6. eq [x]
        
    */ 

    function test_lt(uint256 value,uint256 target_value) public {

        vm.assume(value > 0 && target_value > 0);
        // bound()
        bytes memory predicate = generateCalldata.generateCalldatadynamic("lt",value,target_value);
        
        // target_value < value
        if (value > target_value) {
        // Expect verify to return true if "value" is greater than "target_value"
            verifyPredicate.verify(predicate);
        } else {
        // Expect verify to return false if "value" is not less than "target_value"
        vm.expectRevert();
        verifyPredicate.verify(predicate);
    }
    }
     
    function test_gt(uint256 value,uint256 target_value) public {

        vm.assume(value > 0 && target_value > 0);
        
        bytes memory predicate = generateCalldata.generateCalldatadynamic("gt",value,target_value);
        
        if (value < target_value) {
        // Expect verify to return true if target_value is greater than value
            verifyPredicate.verify(predicate);
          
        } else {
        // Expect verify to return false if value is not greater than target_value
        vm.expectRevert();
        verifyPredicate.verify(predicate);
    
    }
    }

    function test_eq(uint256 value,uint256 target_value) public {

        vm.assume(value > 0 && target_value > 0);
        
        bytes memory predicate = generateCalldata.generateCalldatadynamic("eq",value,target_value);
        
        if (value == target_value) {
        // Expect verify to return true if target_value is greater than value
            verifyPredicate.verify(predicate);
          
        } else {
        // Expect verify to return false if value is not greater than target_value
        vm.expectRevert();
        verifyPredicate.verify(predicate);
    
    }
    }
    
    function test_and_lt_gt(uint256 value_1,uint256 target_value_1,uint256 value_2,uint256 target_value_2) public{

        bytes memory predicate = generateCalldata.generateCalldataAnd_lt_gt(value_1, target_value_1, value_2, target_value_2);
        
        if ((target_value_1 < value_1) && (target_value_2 > value_2)){
            verifyPredicate.verify(predicate);
        }

        else{
            vm.expectRevert();
            verifyPredicate.verify(predicate);
        }
    }

    function test_or_lt_gt(uint256 value_1,uint256 target_value_1,uint256 value_2,uint256 target_value_2) public{

        bytes memory predicate = generateCalldata.generateCalldataOr_lt_gt(value_1, target_value_1, value_2, target_value_2);
        
        if ((target_value_1 < value_1) || (target_value_2 > value_2)){
            verifyPredicate.verify(predicate);
        }

        else{
            vm.expectRevert();
            verifyPredicate.verify(predicate);
        }
    }

    function test_not() view public {
        
        bytes memory predicate = generateCalldata.generateCalldataNot();
    
        verifyPredicate.verify(predicate);
        
    }


    }


