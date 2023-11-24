// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "./../src/Predicates.sol";
import "./../src/interfaces/IPredicates.sol";
import "./../src/AdvancedOrderEngine.sol";
import "./../src/AdvancedOrderEngineErrors.sol";
import "openzeppelin/token/ERC20/IERC20.sol";

contract AdvancedOrderEngineTest is Test {
    Predicates predicates;
    AdvancedOrderEngine advancedOrderEngine;
    address zeroAddress = address(0);
    address feeCollector = address(1);
    address operator = address(2);
    address admin = address(3);

    function setUp() public {
        vm.startPrank(admin);

        predicates = new Predicates();
        advancedOrderEngine = new AdvancedOrderEngine(IPredicates(address(predicates)), feeCollector);

        advancedOrderEngine.manageOperatorPrivilege(operator, true);

        vm.stopPrank();
    }

    function testOperatorPriviledge() public {
        vm.startPrank(admin);

        address testOperator = address(99);

        assertEq(advancedOrderEngine.isOperator(testOperator), false);
        
        advancedOrderEngine.manageOperatorPrivilege(testOperator, true);
        assertEq(advancedOrderEngine.isOperator(testOperator), true);

        vm.expectRevert(AccessStatusUnchanged.selector);
        advancedOrderEngine.manageOperatorPrivilege(testOperator, true);
        
        advancedOrderEngine.manageOperatorPrivilege(testOperator, false);
        assertEq(advancedOrderEngine.isOperator(testOperator), false);

        vm.expectRevert(ZeroAddress.selector);
        advancedOrderEngine.manageOperatorPrivilege(zeroAddress, false);

        vm.stopPrank();

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        advancedOrderEngine.manageOperatorPrivilege(zeroAddress, false);
    }

    function testUpdateTokenWhitelist() public {
        vm.startPrank(admin);

        IERC20[] memory tokens = new IERC20[](2);
        bool[] memory access = new bool[](2);

        tokens[0] = IERC20(address(1)); // Assuming these addresses are valid ERC20 tokens
        tokens[1] = IERC20(address(2));

        // Initial status should be not whitelisted
        assertEq(advancedOrderEngine.isWhitelistedToken(tokens[0]), false);
        assertEq(advancedOrderEngine.isWhitelistedToken(tokens[1]), false);

        // Whitelisting tokens
        access[0] = true;
        access[1] = true;
        advancedOrderEngine.updateTokenWhitelist(tokens, access);

        // Verify the tokens are now whitelisted
        assertEq(advancedOrderEngine.isWhitelistedToken(tokens[0]), true);
        assertEq(advancedOrderEngine.isWhitelistedToken(tokens[1]), true);

        // Test for AccessStatusUnchanged revert
        vm.expectRevert(AccessStatusUnchanged.selector);
        advancedOrderEngine.updateTokenWhitelist(tokens, access);

        // Remove from whitelist
        access[0] = false;
        access[1] = false;
        advancedOrderEngine.updateTokenWhitelist(tokens, access);

        // Verify the tokens are no longer whitelisted
        assertEq(advancedOrderEngine.isWhitelistedToken(tokens[0]), false);
        assertEq(advancedOrderEngine.isWhitelistedToken(tokens[1]), false);

        // Test for ZeroAddress revert
        tokens[0] = IERC20(address(0)); // Zero address token
        vm.expectRevert(ZeroAddress.selector);
        advancedOrderEngine.updateTokenWhitelist(tokens, access);

        // Test for ArraysLengthMismatch revert
        IERC20[] memory mismatchedTokens = new IERC20[](1);
        bool[] memory mismatchedAccess = new bool[](2);
        vm.expectRevert(ArraysLengthMismatch.selector);
        advancedOrderEngine.updateTokenWhitelist(mismatchedTokens, mismatchedAccess);

        // Test for onlyOwner modifier
        vm.stopPrank();
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        advancedOrderEngine.updateTokenWhitelist(tokens, access);
    }

    function testChangePredicateAddress() public {
        vm.startPrank(admin);

        IPredicates newPredicatesAddr = IPredicates(address(3)); // Assuming this is a valid address

        // Change to a new address
        advancedOrderEngine.changePredicateAddress(newPredicatesAddr);
        assertEq(address(advancedOrderEngine.predicates()), address(newPredicatesAddr));

        // Test for ZeroAddress revert
        vm.expectRevert(ZeroAddress.selector);
        advancedOrderEngine.changePredicateAddress(IPredicates(address(0)));

        // Test for SamePredicateAddress revert
        vm.expectRevert(SamePredicateAddress.selector);
        advancedOrderEngine.changePredicateAddress(newPredicatesAddr);

        // Test for onlyOwner modifier
        vm.stopPrank();
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        advancedOrderEngine.changePredicateAddress(newPredicatesAddr);
    }

    function testChangeFeeCollectorAddress() public {
        vm.startPrank(admin);

        address newFeeCollectorAddr = address(4); // Assuming this is a valid address

        // Change to a new fee collector address
        advancedOrderEngine.changeFeeCollectorAddress(newFeeCollectorAddr);
        assertEq(advancedOrderEngine.feeCollector(), newFeeCollectorAddr);

        // Test for ZeroAddress revert
        vm.expectRevert(ZeroAddress.selector);
        advancedOrderEngine.changeFeeCollectorAddress(address(0));

        // Test for SameFeeCollectorAddress revert
        vm.expectRevert(SameFeeCollectorAddress.selector);
        advancedOrderEngine.changeFeeCollectorAddress(newFeeCollectorAddr);

        // Test for onlyOwner modifier
        vm.stopPrank();
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        advancedOrderEngine.changeFeeCollectorAddress(newFeeCollectorAddr);
    }

    


    function testFillOrders() public {

    }

}