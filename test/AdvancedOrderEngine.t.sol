// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "./../src/Predicates.sol";
import "./../src/interfaces/IPredicates.sol";
import "./../src/AdvancedOrderEngine.sol";
import "./../src/AdvancedOrderEngineErrors.sol";
import "./../src/libraries/OrderEngine.sol";
import "./../src/Helper/GenerateCalldata.sol";
import "./interfaces/swaprouter.sol";
import "./interfaces/weth9.sol";
import "./interfaces/pricefeed.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";

contract AdvancedOrderEngineTest is Test {
    Predicates predicates;
    AdvancedOrderEngine advancedOrderEngine;
    GenerateCalldata generateCalldata;
    IERC20 wmatic = IERC20(0x7c9f4C87d911613Fe9ca58b579f737911AAD2D43);
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ISwapRouter02 swapRouter02 = ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    IPriceFeed usdc_eth = IPriceFeed(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
    address zeroAddress = address(0);
    address feeCollector = address(147578);
    address admin = address(3);
    uint256 maker1PrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; //also owner of contract
    address maker1 = vm.addr(maker1PrivateKey);
    uint256 maker2PrivateKey = 0xac0974bec39a17e36ba4a6b4d233ff944bacb478cbed5efcae784d7bf4f2ff80; //also owner of contract
    address maker2 = vm.addr(maker2PrivateKey);
    uint256 operatorPrivateKey = 0xB0B; 
    address operator = vm.addr(operatorPrivateKey);


    function setUp() public {
        vm.startPrank(admin);

        predicates = new Predicates();
        generateCalldata = new GenerateCalldata(address(predicates));
        advancedOrderEngine = new AdvancedOrderEngine(IPredicates(address(predicates)), feeCollector);

        advancedOrderEngine.manageOperatorPrivilege(operator, true);

        IERC20[] memory tokens = new IERC20[](2);
        bool[] memory access = new bool[](2);

        tokens[0] = usdc; // Assuming these addresses are valid ERC20 tokens
        tokens[1] = weth;

        // Whitelisting tokens
        access[0] = true;
        access[1] = true;
        advancedOrderEngine.updateTokenWhitelist(tokens, access);

        vm.deal(maker1, 20 ether);
        vm.deal(maker2, 20 ether);
        vm.deal(operator, 20 ether);
        vm.deal(admin, 20 ether);
    
        vm.stopPrank();

        vm.startPrank(maker2);

        usdc.approve(address(swapRouter02), UINT256_MAX);
        usdc.approve(address(advancedOrderEngine), UINT256_MAX);

        // get usdc
        swapRouter02.exactInputSingle{value: 1 ether}(
            ISwapRouter02.ExactInputSingleParams (
                address(weth),
                address(usdc),
                500,
                maker2,
                1 ether,
                0,
                0
            )
        );

        vm.stopPrank();

        vm.startPrank(maker1);

        weth.approve(address(swapRouter02), UINT256_MAX);
        weth.approve(address(advancedOrderEngine), UINT256_MAX);

        // get weth
        IWETH9(address(weth)).deposit{value: 1 ether}();

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
        uint beforeUsdcMaker2 = usdc.balanceOf(maker2);
        uint beforeWethMaker2 = weth.balanceOf(maker2);
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        uint beforeWethMaker1 = weth.balanceOf(maker1);

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory buyOrder,
            OrderEngine.Order memory sellOrder
        ) = getStandardInput();

        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        vm.stopPrank();

        uint afterUsdcMaker2 = usdc.balanceOf(maker2);
        uint afterWethMaker2 = weth.balanceOf(maker2);
        uint afterUsdcMaker1 = usdc.balanceOf(maker1);
        uint afterWethMaker1 = weth.balanceOf(maker1);

        assertEq(beforeUsdcMaker2, afterUsdcMaker2 + sellOrder.sellTokenAmount);
        assertEq(beforeWethMaker2 + sellOrder.buyTokenAmount, afterWethMaker2);
        assertEq(beforeUsdcMaker1 + buyOrder.buyTokenAmount, afterUsdcMaker1);
        assertEq(beforeWethMaker1 , afterWethMaker1 + buyOrder.sellTokenAmount);
    }

    function testNoOrderInputFillOrders() public {
        uint beforeUsdcMaker2 = usdc.balanceOf(maker2);
        uint beforeWethMaker2 = weth.balanceOf(maker2);
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        uint beforeWethMaker1 = weth.balanceOf(maker1);

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,,
        ) = getStandardInput();

        orders = new OrderEngine.Order[](0);

        vm.expectRevert(EmptyArray.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        vm.stopPrank();

        uint afterUsdcMaker2 = usdc.balanceOf(maker2);
        uint afterWethMaker2 = weth.balanceOf(maker2);
        uint afterUsdcMaker1 = usdc.balanceOf(maker1);
        uint afterWethMaker1 = weth.balanceOf(maker1);

        assertEq(beforeUsdcMaker2, afterUsdcMaker2);
        assertEq(beforeWethMaker2, afterWethMaker2);
        assertEq(beforeUsdcMaker1, afterUsdcMaker1);
        assertEq(beforeWethMaker1 , afterWethMaker1);
    }

    function testInvalidInputFillOrders() public {
        uint beforeUsdcMaker2 = usdc.balanceOf(maker2);
        uint beforeWethMaker2 = weth.balanceOf(maker2);
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        uint beforeWethMaker1 = weth.balanceOf(maker1);

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,,
            OrderEngine.Order memory sellOrder
        ) = getStandardInput();

        sellOrder.validTill = block.timestamp - 1000;
        orders[0] = sellOrder;

        // expired order
        vm.expectRevert(
            abi.encodeWithSelector(
                OrderExpired.selector,
                advancedOrderEngine.getOrderHash(sellOrder)
            )
        );
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        // zero amount
        sellOrder.validTill = block.timestamp + 1000;
        uint prevSellAmount = sellOrder.sellTokenAmount;
        sellOrder.sellTokenAmount = 0;
        orders[0] = sellOrder;

        // zero amount 
        vm.expectRevert(ZeroAmount.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        // not white listed token
        sellOrder.sellTokenAmount = prevSellAmount;
        IERC20 prevToken = sellOrder.sellToken;
        sellOrder.sellToken = wmatic;
        orders[0] = sellOrder;

        vm.expectRevert(TokenNotWhitelisted.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        // not zero address token
        sellOrder.sellTokenAmount = prevSellAmount;
        sellOrder.sellToken = IERC20(address(0));
        orders[0] = sellOrder;

        vm.expectRevert(TokenNotWhitelisted.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        // zero address operator
        sellOrder.sellToken = prevToken;
        sellOrder.operator = address(99);
        orders[0] = sellOrder;

        vm.expectRevert(PrivateOrder.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        // zero address operator
        sellOrder.operator = address(0);
        orders[0] = sellOrder;

        vm.expectRevert(InvalidSignature.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );
        
        vm.stopPrank();

        uint afterUsdcMaker2 = usdc.balanceOf(maker2);
        uint afterWethMaker2 = weth.balanceOf(maker2);
        uint afterUsdcMaker1 = usdc.balanceOf(maker1);
        uint afterWethMaker1 = weth.balanceOf(maker1);

        assertEq(beforeUsdcMaker2, afterUsdcMaker2);
        assertEq(beforeWethMaker2, afterWethMaker2);
        assertEq(beforeUsdcMaker1, afterUsdcMaker1);
        assertEq(beforeWethMaker1 , afterWethMaker1);
    }

    function testOrderReplay() public {

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,,
        ) = getStandardInput();

        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );
        
        // order replay
        vm.expectRevert(OrderFilledAlready.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );
        
        vm.stopPrank();
    }

    function testInputLengthMismatchFillOrders() public {
        uint beforeUsdcMaker2 = usdc.balanceOf(maker2);
        uint beforeWethMaker2 = weth.balanceOf(maker2);
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        uint beforeWethMaker1 = weth.balanceOf(maker1);

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory buyOrder,
            OrderEngine.Order memory sellOrder
        ) = getStandardInput();

        orders = new OrderEngine.Order[](1);

        orders[0] = sellOrder;

        // if orderlength != sell order or buy order length
        vm.expectRevert(ArraysLengthMismatch.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        // if sell order != order || buy order || sig
        orders = new OrderEngine.Order[](2);

        orders[0] = sellOrder;
        orders[1] = buyOrder;

        sell = new uint256[](1);

        sell[0] = sellOrder.sellTokenAmount;

        vm.expectRevert(ArraysLengthMismatch.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        // if buy order != sell order || order || sig
        buy = new uint256[](1);

        buy[0] = sellOrder.buyTokenAmount;
        // buy[1] = buyOrder.buyTokenAmount;
        
        sell = new uint256[](2);

        sell[0] = sellOrder.sellTokenAmount;
        sell[1] = buyOrder.sellTokenAmount;

        vm.expectRevert(ArraysLengthMismatch.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        // if sig != buy order || sell order || sig
        buy = new uint256[](2);

        buy[0] = sellOrder.buyTokenAmount;
        buy[1] = buyOrder.buyTokenAmount;
        
        signatures = new bytes[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker2PrivateKey, _hashTypedDataV4(OrderEngine.hash(sellOrder)));
        bytes memory sellOrderSignature = abi.encodePacked(r, s, v);

        signatures[0] = sellOrderSignature;

        vm.expectRevert(ArraysLengthMismatch.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        vm.stopPrank();

        uint afterUsdcMaker2 = usdc.balanceOf(maker2);
        uint afterWethMaker2 = weth.balanceOf(maker2);
        uint afterUsdcMaker1 = usdc.balanceOf(maker1);
        uint afterWethMaker1 = weth.balanceOf(maker1);

        assertEq(beforeUsdcMaker2, afterUsdcMaker2);
        assertEq(beforeWethMaker2, afterWethMaker2);
        assertEq(beforeUsdcMaker1, afterUsdcMaker1);
        assertEq(beforeWethMaker1 , afterWethMaker1);
    }

    function testPartiallyFillableOrder() public {
        uint beforeUsdcMaker2 = usdc.balanceOf(maker2);
        uint beforeWethMaker2 = weth.balanceOf(maker2);
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        uint beforeWethMaker1 = weth.balanceOf(maker1);

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory buyOrder,
            OrderEngine.Order memory sellOrder
        ) = getStandardInput();

        sell[0] = sellOrder.sellTokenAmount / 2;
        sell[1] = buyOrder.sellTokenAmount / 2;
        buy[0] = sellOrder.buyTokenAmount / 2;
        buy[1] = buyOrder.buyTokenAmount / 2;

        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        vm.stopPrank();

        uint afterUsdcMaker2 = usdc.balanceOf(maker2);
        uint afterWethMaker2 = weth.balanceOf(maker2);
        uint afterUsdcMaker1 = usdc.balanceOf(maker1);
        uint afterWethMaker1 = weth.balanceOf(maker1);

        assertEq(beforeUsdcMaker2, afterUsdcMaker2 + sellOrder.sellTokenAmount / 2);
        assertEq(beforeWethMaker2 + sellOrder.buyTokenAmount / 2, afterWethMaker2);
        assertEq(beforeUsdcMaker1 + buyOrder.buyTokenAmount / 2, afterUsdcMaker1);
        assertEq(beforeWethMaker1 , afterWethMaker1 + buyOrder.sellTokenAmount / 2);
    }

    function testExceedsOrderSellAmount() public {

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory buyOrder,
            OrderEngine.Order memory sellOrder
        ) = getStandardInput();

        sell[0] = sellOrder.sellTokenAmount * 2;
        sell[1] = buyOrder.sellTokenAmount * 2;
        buy[0] = sellOrder.buyTokenAmount * 2;
        buy[1] = buyOrder.buyTokenAmount * 2;

        vm.expectRevert(ExceedsOrderSellAmount.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        vm.stopPrank();
    }

    function testPartiallyFillableOrderFail() public {

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,,
        ) = getStandardInput();

        sell[0] = 8 * 10 ** 6;
        sell[1] = 0.0022 * 10 ** 18;

        buy[0] = 0.0022 * 10 ** 18;
        buy[1] = 8 * 10 ** 6;

        vm.expectRevert(LimitPriceNotRespected.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        vm.stopPrank();
    }

    function testInvalidSignature() public {

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,,
        ) = getStandardInput();

        bytes memory temp = signatures[0];
        signatures[0] = signatures[1];
        signatures[1] = temp;
        
        vm.expectRevert(InvalidSignature.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        vm.stopPrank();
    }

    function testFillOrKillFail() public {

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory buyOrder,
            OrderEngine.Order memory sellOrder
        ) = getStandardInput();

        sell[0] = sellOrder.sellTokenAmount / 2;
        sell[1] = buyOrder.sellTokenAmount / 2;
        buy[0] = sellOrder.buyTokenAmount / 2;
        buy[1] = buyOrder.buyTokenAmount / 2;

        orders[0].isPartiallyFillable = false;
        orders[1].isPartiallyFillable = false;
        
        vm.expectRevert(LimitPriceNotRespected.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        vm.stopPrank();
    }

    function testPredicateFail() public {


        // English: Only allow order execution if the return value from an arbitrary call is greater than some contraint.
        // Predicate: gt(constraint(99999 * 10 ** 18), arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress))

        // Step 1: Generate calldata to send to our target contract
        bytes memory targetContractCalldata = abi.encodeWithSelector(
            usdc_eth.latestAnswer.selector
        ); // 'callDataToSendToTargetAddress'

        // Step 2: Generate predicates contract "arbitrary static call" function calldata
        bytes memory arbitraryStaticCalldata = abi.encodeWithSignature(
            "arbitraryStaticCall(address,bytes)",
            address(usdc_eth),
            targetContractCalldata
        ); // arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress)

        // Step 3: Generate predicates contract "lt" function calldata
        bytes memory ltFnCalldata = abi.encodeWithSignature(
            "gt(uint256,bytes)",
            _oraclePrice(),
            arbitraryStaticCalldata
        ); // lt(15, arbitraryS
        // generateCalldata1

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory buyOrder,
            OrderEngine.Order memory sellOrder
        ) = getStandardInput();

        orders[0].predicateCalldata = ltFnCalldata;
        orders[1].predicateCalldata = ltFnCalldata;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker2PrivateKey, _hashTypedDataV4(OrderEngine.hash(sellOrder)));
        bytes memory sellOrderSignature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker1PrivateKey, _hashTypedDataV4(OrderEngine.hash(buyOrder)));
        bytes memory buyOrderSignature = abi.encodePacked(r, s, v);

        signatures[0] = sellOrderSignature;
        signatures[1] = buyOrderSignature;

        vm.expectRevert(PredicateIsNotTrue.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        vm.stopPrank();
    }

    function testPredicate() public {


        // English: Only allow order execution if the return value from an arbitrary call is greater than some contraint.
        // Predicate: gt(constraint(99999 * 10 ** 18), arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress))

        // Step 1: Generate calldata to send to our target contract
        bytes memory targetContractCalldata = abi.encodeWithSelector(
            usdc_eth.latestAnswer.selector
        ); // 'callDataToSendToTargetAddress'

        // Step 2: Generate predicates contract "arbitrary static call" function calldata
        bytes memory arbitraryStaticCalldata = abi.encodeWithSignature(
            "arbitraryStaticCall(address,bytes)",
            address(usdc_eth),
            targetContractCalldata
        ); // arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress)

        // Step 3: Generate predicates contract "lt" function calldata
        bytes memory ltFnCalldata = abi.encodeWithSignature(
            "lt(uint256,bytes)",
            _oraclePrice(),
            arbitraryStaticCalldata
        ); // lt(15, arbitraryS
        // generateCalldata1

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory buyOrder,
            OrderEngine.Order memory sellOrder
        ) = getStandardInput();

        orders[0].predicateCalldata = ltFnCalldata;
        orders[1].predicateCalldata = ltFnCalldata;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker2PrivateKey, _hashTypedDataV4(OrderEngine.hash(sellOrder)));
        bytes memory sellOrderSignature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker1PrivateKey, _hashTypedDataV4(OrderEngine.hash(buyOrder)));
        bytes memory buyOrderSignature = abi.encodePacked(r, s, v);

        signatures[0] = sellOrderSignature;
        signatures[1] = buyOrderSignature;

        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        vm.stopPrank();
    }

    function getDummyBuyOrder() private view returns(OrderEngine.Order memory) {
        return OrderEngine.Order(
            123, // nonce value
            block.timestamp + 3600, // valid till
            4800000000000000, // 0.0048 weth - sell token
            10000000, // 10 USDC - buy amount
            0, // fee
            maker1, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            maker1, // Recipient's Ethereum address
            weth, // MATIC token address - sell token
            usdc, // USDC token address - buy token
            true, // is partially fillable
            "0x", // facilitator call data 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
        );
    }

    function getDummySellOrder() private view returns(OrderEngine.Order memory) {
        return OrderEngine.Order(
            124, // nonce value
            block.timestamp + 3600, // valid till
            10000000, // 10 USDC - sell token amount
            4800000000000000, // 0.0048 weth - buy token amount
            0, // fee
            maker2, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            maker2, // Recipient's Ethereum address
            usdc, // USDC token address - sell token
            weth, // MATIC token address - buy token
            true, // is partially fillable
            "0x", // facilitator calldata 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
        );
    }

    function getStandardInput() private view returns(
        OrderEngine.Order[] memory orders,
        uint256[] memory sell,
        uint256[] memory buy,
        bytes[] memory signatures,
        bytes memory facilitatorInteraction,
        IERC20[] memory borrowedTokens,
        uint256[] memory borrowedAmounts,
        OrderEngine.Order memory buyOrder,
        OrderEngine.Order memory sellOrder
    ) {

        buyOrder = getDummyBuyOrder();
        sellOrder = getDummySellOrder();

        orders = new OrderEngine.Order[](2);

        orders[0] = sellOrder;
        orders[1] = buyOrder;

        sell = new uint256[](2);

        sell[0] = sellOrder.sellTokenAmount;
        sell[1] = buyOrder.sellTokenAmount;

        buy = new uint256[](2);

        buy[0] = sellOrder.buyTokenAmount;
        buy[1] = buyOrder.buyTokenAmount;

        signatures = new bytes[](2);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker2PrivateKey, _hashTypedDataV4(OrderEngine.hash(sellOrder)));
        bytes memory sellOrderSignature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker1PrivateKey, _hashTypedDataV4(OrderEngine.hash(buyOrder)));
        bytes memory buyOrderSignature = abi.encodePacked(r, s, v);

        signatures[0] = sellOrderSignature;
        signatures[1] = buyOrderSignature;

        facilitatorInteraction = "0x";
        borrowedAmounts = new uint256[](0);
        borrowedTokens = new IERC20[](0);
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(advancedOrderEngine.DOMAIN_SEPARATOR(), structHash);
    }

    function _oraclePrice() internal view virtual returns (uint256) {
        return 99999 ether;
    }

}

/** Predicates selectors
 * and = 0x616e6400
 * or = 0x6f720000
 */