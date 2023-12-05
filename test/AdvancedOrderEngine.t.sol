// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "./../src/Predicates.sol";
import "./../src/interfaces/IPredicates.sol";
import "./../src/AdvancedOrderEngine.sol";
import "./../src/AdvancedOrderEngineErrors.sol";
import "./../src/libraries/OrderEngine.sol";
import "./../src/Helper/GenerateCalldata.sol";
import "./../src/Mocks/CallSwap.sol";
import "./../src/Mocks/FacilitatorSwap.sol";
import "./../src/Mocks/CallTransfer.sol";
import "./interfaces/swaprouter.sol";
import "./interfaces/weth9.sol";
import "./interfaces/pricefeed.sol";
import "./interfaces/quoter.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";

contract AdvancedOrderEngineTest is Test {
    Predicates predicates;
    AdvancedOrderEngine advancedOrderEngine;
    GenerateCalldata generateCalldata;
    address helper;
    address swapper;
    IERC20 wmatic = IERC20(0x7c9f4C87d911613Fe9ca58b579f737911AAD2D43);
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IWETH9 weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 wbtc = IERC20(0x9Ee1Aa18F3FEB435f811d6AE2F71B7D2a4Adce0B);
    ISwapRouter02 swapRouter02 = ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    IPriceFeed usdc_eth = IPriceFeed(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
    IQuoter qouter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    IQuoter positions = IQuoter(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address zeroAddress = address(0);
    address feeCollector = address(147578);
    address admin = address(3);
    uint256 maker1PrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address maker1 = vm.addr(maker1PrivateKey);
    uint256 maker2PrivateKey = 0xac0974bec39a17e36ba4a6b4d233ff944bacb478cbed5efcae784d7bf4f2ff80;
    address maker2 = vm.addr(maker2PrivateKey);
    uint256 maker3PrivateKey = 0xac0974bec38a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address maker3 = vm.addr(maker3PrivateKey);
    uint256 operatorPrivateKey = 0xB0B; 
    address operator = vm.addr(operatorPrivateKey);


    function setUp() public {
        vm.startPrank(admin);

        predicates = new Predicates();
        generateCalldata = new GenerateCalldata(address(predicates));
        advancedOrderEngine = new AdvancedOrderEngine(IPredicates(address(predicates)), feeCollector);
        swapper = address(new Swapper());
        helper = address(new Helper());

        advancedOrderEngine.manageOperatorPrivilege(operator, true);

        IERC20[] memory tokens = new IERC20[](3);
        bool[] memory access = new bool[](3);

        tokens[0] = usdc; // Assuming these addresses are valid ERC20 tokens
        tokens[1] = weth;
        tokens[2] = wmatic;

        // Whitelisting tokens
        access[0] = true;
        access[1] = true;
        access[2] = true;
        advancedOrderEngine.updateTokenWhitelist(tokens, access);

        vm.deal(maker1, 20 ether);
        vm.deal(maker2, 20 ether);
        vm.deal(maker3, 20 ether);
        vm.deal(operator, 20 ether);
        vm.deal(admin, 20 ether);
    
        vm.stopPrank();

        vm.startPrank(maker2);

        weth.approve(address(swapRouter02), UINT256_MAX);
        weth.approve(address(advancedOrderEngine), UINT256_MAX);

        // get weth
        weth.deposit{value: 1 ether}();

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
        weth.deposit{value: 1 ether}();

        usdc.approve(address(swapRouter02), UINT256_MAX);
        usdc.approve(address(advancedOrderEngine), UINT256_MAX);

        // get usdc
        swapRouter02.exactInputSingle{value: 1 ether}(
            ISwapRouter02.ExactInputSingleParams (
                address(weth),
                address(usdc),
                500,
                maker1,
                1 ether,
                0,
                0
            )
        );

        vm.stopPrank();

        vm.startPrank(maker3);

        weth.approve(address(swapRouter02), UINT256_MAX);
        weth.approve(address(advancedOrderEngine), UINT256_MAX);

        // get weth
        weth.deposit{value: 1 ether}();

        usdc.approve(address(swapRouter02), UINT256_MAX);
        usdc.approve(address(advancedOrderEngine), UINT256_MAX);

        // get usdc
        swapRouter02.exactInputSingle{value: 1 ether}(
            ISwapRouter02.ExactInputSingleParams (
                address(weth),
                address(usdc),
                500,
                maker3,
                1 ether,
                0,
                0
            )
        );


        wmatic.approve(address(swapRouter02), UINT256_MAX);
        wmatic.approve(address(advancedOrderEngine), UINT256_MAX);

        // get matic
        swapRouter02.exactInputSingle{value: 1 ether}(
            ISwapRouter02.ExactInputSingleParams (
                address(weth),
                address(wmatic),
                3000,
                maker3,
                1 ether,
                0,
                0
            )
        );

        vm.stopPrank();

        vm.startPrank(operator);

        weth.approve(address(swapRouter02), UINT256_MAX);
        weth.approve(address(advancedOrderEngine), UINT256_MAX);

        // get weth
        weth.deposit{value: 1 ether}();

        usdc.approve(address(swapRouter02), UINT256_MAX);
        usdc.approve(address(advancedOrderEngine), UINT256_MAX);

        // get usdc
        swapRouter02.exactInputSingle{value: 1 ether}(
            ISwapRouter02.ExactInputSingleParams (
                address(weth),
                address(usdc),
                500,
                operator,
                1 ether,
                0,
                0
            )
        );

        vm.stopPrank();
    }

    function testWithdraw() public {

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,,,
        ) = getStandardInput1();

        vm.prank(operator);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        vm.startPrank(admin);

        vm.expectRevert(ZeroAddress.selector);
        advancedOrderEngine.withdraw(
            address(0),
            1 * 10 ** 6,
            admin
        );

        vm.expectRevert(ZeroAddress.selector);
        advancedOrderEngine.withdraw(
            address(usdc),
            1 * 10 ** 6,
            address(0)
        );

        vm.expectRevert();
        advancedOrderEngine.withdraw(
            address(usdc),
            2 * 10 ** 6,
            address(0)
        );

        uint256 balBefore = usdc.balanceOf(admin);
        advancedOrderEngine.withdraw(
            address(usdc),
            1 * 10 ** 6,
            admin
        );
        uint256 balAfter = usdc.balanceOf(admin);

        assertEq(balBefore + 1 * 10 ** 6, balAfter);

        vm.stopPrank();

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        advancedOrderEngine.withdraw(
            address(usdc),
            1 * 10 ** 6,
            admin
        );
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

        assertEq(beforeUsdcMaker2, afterUsdcMaker2 + sellOrder.a.sellTokenAmount);
        assertEq(beforeWethMaker2 + sellOrder.a.buyTokenAmount, afterWethMaker2);
        assertEq(beforeUsdcMaker1 + buyOrder.a.buyTokenAmount, afterUsdcMaker1);
        assertEq(beforeWethMaker1 , afterWethMaker1 + buyOrder.a.sellTokenAmount);
    }

    function testRingOrders() public {
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        uint beforeWethMaker1 = weth.balanceOf(maker1);
        uint beforeWethMaker2 = weth.balanceOf(maker2);
        uint beforeMaticMaker2 = wmatic.balanceOf(maker2);
        uint beforeUsdcMaker3 = usdc.balanceOf(maker3);
        uint beforeMaticMaker3 = wmatic.balanceOf(maker3);

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory order1,
            OrderEngine.Order memory order2,
            OrderEngine.Order memory order3
        ) = getStandardInput4();

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

        uint afterUsdcMaker1 = usdc.balanceOf(maker1);
        uint afterWethMaker1 = weth.balanceOf(maker1);
        uint afterWethMaker2 = weth.balanceOf(maker2);
        uint afterMaticMaker2 = wmatic.balanceOf(maker2);
        uint afterUsdcMaker3 = usdc.balanceOf(maker3);
        uint afterMaticMaker3 = wmatic.balanceOf(maker3);

        assertEq(beforeUsdcMaker1, afterUsdcMaker1 + order1.a.sellTokenAmount);
        assertEq(beforeWethMaker1 + order1.a.buyTokenAmount , afterWethMaker1);
        assertEq(beforeWethMaker2, afterWethMaker2 + order2.a.sellTokenAmount);
        assertEq(beforeMaticMaker2 + order2.a.buyTokenAmount, afterMaticMaker2);
        assertEq(beforeMaticMaker3, afterMaticMaker3 + order3.a.sellTokenAmount);
        assertEq(beforeUsdcMaker3 + order3.a.buyTokenAmount, afterUsdcMaker3);
    }

    function testFillOrderInChunks() public {
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
            OrderEngine.Order memory order1,
            OrderEngine.Order memory order2
        ) = getStandardInput();

        sell = new uint256[](2);

        sell[0] = order2.a.sellTokenAmount / 2;
        sell[1] = order1.a.sellTokenAmount / 2;

        buy = new uint256[](2);

        buy[0] = order2.a.buyTokenAmount / 2;
        buy[1] = order1.a.buyTokenAmount / 2;

        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
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

        vm.stopPrank();

        uint afterUsdcMaker2 = usdc.balanceOf(maker2);
        uint afterWethMaker2 = weth.balanceOf(maker2);
        uint afterUsdcMaker1 = usdc.balanceOf(maker1);
        uint afterWethMaker1 = weth.balanceOf(maker1);

        assertEq(beforeUsdcMaker2, afterUsdcMaker2 + order2.a.sellTokenAmount);
        assertEq(beforeWethMaker2 + order2.a.buyTokenAmount, afterWethMaker2);
        assertEq(beforeUsdcMaker1 + order1.a.buyTokenAmount, afterUsdcMaker1);
        assertEq(beforeWethMaker1 , afterWethMaker1 + order1.a.sellTokenAmount);
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

        sellOrder.a.validTill = block.timestamp - 1000;
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
        sellOrder.a.validTill = block.timestamp + 1000;
        uint prevSellAmount = sellOrder.a.sellTokenAmount;
        sellOrder.a.sellTokenAmount = 0;
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
        sellOrder.a.sellTokenAmount = prevSellAmount;
        IERC20 prevToken = sellOrder.b.sellToken;
        sellOrder.b.sellToken = wbtc;
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
        sellOrder.a.sellTokenAmount = prevSellAmount;
        sellOrder.b.sellToken = IERC20(address(0));
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
        sellOrder.b.sellToken = prevToken;
        sellOrder.b.operator = address(99);
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
        sellOrder.b.operator = address(0);
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

        sell[0] = sellOrder.a.sellTokenAmount;

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

        buy[0] = sellOrder.a.buyTokenAmount;
        // buy[1] = buyOrder.a.buyTokenAmount;
        
        sell = new uint256[](2);

        sell[0] = sellOrder.a.sellTokenAmount;
        sell[1] = buyOrder.a.sellTokenAmount;

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

        buy[0] = sellOrder.a.buyTokenAmount;
        buy[1] = buyOrder.a.buyTokenAmount;
        
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

        sell[0] = sellOrder.a.sellTokenAmount / 2;
        sell[1] = buyOrder.a.sellTokenAmount / 2;
        buy[0] = sellOrder.a.buyTokenAmount / 2;
        buy[1] = buyOrder.a.buyTokenAmount / 2;

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

        assertEq(beforeUsdcMaker2, afterUsdcMaker2 + sellOrder.a.sellTokenAmount / 2);
        assertEq(beforeWethMaker2 + sellOrder.a.buyTokenAmount / 2, afterWethMaker2);
        assertEq(beforeUsdcMaker1 + buyOrder.a.buyTokenAmount / 2, afterUsdcMaker1);
        assertEq(beforeWethMaker1 , afterWethMaker1 + buyOrder.a.sellTokenAmount / 2);
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

        sell[0] = sellOrder.a.sellTokenAmount * 2;
        sell[1] = buyOrder.a.sellTokenAmount * 2;
        buy[0] = sellOrder.a.buyTokenAmount * 2;
        buy[1] = buyOrder.a.buyTokenAmount * 2;

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

        sell[0] = sellOrder.a.sellTokenAmount / 2;
        sell[1] = buyOrder.a.sellTokenAmount / 2;
        buy[0] = sellOrder.a.buyTokenAmount / 2;
        buy[1] = buyOrder.a.buyTokenAmount / 2;

        orders[0].c.isPartiallyFillable = false;
        orders[1].c.isPartiallyFillable = false;
        
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

        orders[0].c.predicateCalldata = ltFnCalldata;
        orders[1].c.predicateCalldata = ltFnCalldata;

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

    function testMultiplePredicateOR() public {

        uint beforeUsdcMaker2 = usdc.balanceOf(maker2);
        uint beforeWethMaker2 = weth.balanceOf(maker2);
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        uint beforeWethMaker1 = weth.balanceOf(maker1);

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
        ); // lt(15, arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress))

        // Helpful in generating bytes offset (see below)
        uint256 ltCalldataLength = bytes(ltFnCalldata).length;
        // console.log("LT Calldata length1 ", ltCalldataLength);

        // Step 4: Generate calldata to send to our target contract (for GT)
        targetContractCalldata = abi.encodeWithSelector(
            usdc_eth.latestAnswer.selector
        );

        // Step 5: Generate predicates contract "arbitrary static call" function calldata (for GT)
        arbitraryStaticCalldata = abi.encodeWithSignature(
            "arbitraryStaticCall(address,bytes)",
            address(usdc_eth),
            targetContractCalldata
        ); // arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress)

        // Step 6: Generate predicates contract "gt" function calldata
        // 18 > 5
        bytes memory gtFnCalldata = abi.encodeWithSignature(
            "gt(uint256,bytes)",
            _oraclePrice(),
            arbitraryStaticCalldata
        );

        // Helpful in generating bytes offset (see below)
        uint256 gtCalldataLength = bytes(gtFnCalldata).length;
        // console.log("GT Calldata length ", gtCalldataLength);

        // Step 7: generate 'offset' param value of 'or' fn of predicates contract

        // Generationg offset, required by 'or' fn of predicates contract
        // We have two predicates, length of both predicates in 260, so first predicate offset would be 260 and second would be "firstPredicateLength + 260 = 520"
        bytes memory offsetBytes = abi.encodePacked(uint32(ltCalldataLength + gtCalldataLength), uint32(ltCalldataLength));

        // 'or' fn expects offset in uint256, so padding 0s
        for (uint256 i = (32 - offsetBytes.length) / 4; i > 0; i--) {
            offsetBytes = abi.encodePacked(uint32(0), offsetBytes);
        }
        uint256 offset = uint256(bytes32(offsetBytes));

        // Step 8: combine both 'lt' and 'gt' predicates
        bytes memory jointPredicates = abi.encodePacked(
            bytes(ltFnCalldata),
            bytes(gtFnCalldata)
        );

        // Step 9: Generating 'or' fn calldata
        bytes memory orFnCalldata = abi.encodeWithSignature(
            "or(uint256,bytes)",
            offset,
            jointPredicates
        );

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

        orders[0].c.predicateCalldata = orFnCalldata;
        orders[1].c.predicateCalldata = orFnCalldata;

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

        uint afterUsdcMaker2 = usdc.balanceOf(maker2);
        uint afterWethMaker2 = weth.balanceOf(maker2);
        uint afterUsdcMaker1 = usdc.balanceOf(maker1);
        uint afterWethMaker1 = weth.balanceOf(maker1);

        assertEq(beforeUsdcMaker2, afterUsdcMaker2 + sellOrder.a.sellTokenAmount);
        assertEq(beforeWethMaker2 + sellOrder.a.buyTokenAmount, afterWethMaker2);
        assertEq(beforeUsdcMaker1 + buyOrder.a.buyTokenAmount, afterUsdcMaker1);
        assertEq(beforeWethMaker1 , afterWethMaker1 + buyOrder.a.sellTokenAmount);
    }

    function testMultiplePredicateOR1() public {

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
        ); // lt(15, arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress))

        // Helpful in generating bytes offset (see below)
        uint256 ltCalldataLength = bytes(ltFnCalldata).length;
        // console.log("LT Calldata length1 ", ltCalldataLength);

        // Step 4: Generate calldata to send to our target contract (for GT)
        targetContractCalldata = abi.encodeWithSelector(
            usdc_eth.latestAnswer.selector
        );

        // Step 5: Generate predicates contract "arbitrary static call" function calldata (for GT)
        arbitraryStaticCalldata = abi.encodeWithSignature(
            "arbitraryStaticCall(address,bytes)",
            address(usdc_eth),
            targetContractCalldata
        ); // arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress)

        // Step 6: Generate predicates contract "gt" function calldata
        // 18 > 5
        bytes memory ltFnCalldata1 = abi.encodeWithSignature(
            "lt(uint256,bytes)",
            _oraclePrice(),
            arbitraryStaticCalldata
        );

        // Helpful in generating bytes offset (see below)
        uint256 ltCalldataLength1 = bytes(ltFnCalldata1).length;
        // console.log("GT Calldata length ", gtCalldataLength);

        // Step 7: generate 'offset' param value of 'or' fn of predicates contract

        // Generationg offset, required by 'or' fn of predicates contract
        // We have two predicates, length of both predicates in 260, so first predicate offset would be 260 and second would be "firstPredicateLength + 260 = 520"
        bytes memory offsetBytes = abi.encodePacked(uint32(ltCalldataLength + ltCalldataLength1), uint32(ltCalldataLength));

        // 'or' fn expects offset in uint256, so padding 0s
        for (uint256 i = (32 - offsetBytes.length) / 4; i > 0; i--) {
            offsetBytes = abi.encodePacked(uint32(0), offsetBytes);
        }
        uint256 offset = uint256(bytes32(offsetBytes));

        // Step 8: combine both 'lt' and 'gt' predicates
        bytes memory jointPredicates = abi.encodePacked(
            bytes(ltFnCalldata),
            bytes(ltFnCalldata1)
        );

        // Step 9: Generating 'or' fn calldata
        bytes memory orFnCalldata = abi.encodeWithSignature(
            "or(uint256,bytes)",
            offset,
            jointPredicates
        );

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

        orders[0].c.predicateCalldata = orFnCalldata;
        orders[1].c.predicateCalldata = orFnCalldata;

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

    function testMultiplePredicateORFail() public {

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
        bytes memory gtFnCalldata1 = abi.encodeWithSignature(
            "gt(uint256,bytes)",
            _oraclePrice(),
            arbitraryStaticCalldata
        ); // lt(15, arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress))

        // Helpful in generating bytes offset (see below)
        uint256 gtCalldataLength1 = bytes(gtFnCalldata1).length;
        // console.log("LT Calldata length1 ", ltCalldataLength);

        // Step 4: Generate calldata to send to our target contract (for GT)
        targetContractCalldata = abi.encodeWithSelector(
            usdc_eth.latestAnswer.selector
        );

        // Step 5: Generate predicates contract "arbitrary static call" function calldata (for GT)
        arbitraryStaticCalldata = abi.encodeWithSignature(
            "arbitraryStaticCall(address,bytes)",
            address(usdc_eth),
            targetContractCalldata
        ); // arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress)

        // Step 6: Generate predicates contract "gt" function calldata
        // 18 > 5
        bytes memory gtFnCalldata = abi.encodeWithSignature(
            "gt(uint256,bytes)",
            _oraclePrice(),
            arbitraryStaticCalldata
        );

        // Helpful in generating bytes offset (see below)
        uint256 gtCalldataLength = bytes(gtFnCalldata).length;
        // console.log("GT Calldata length ", gtCalldataLength);

        // Step 7: generate 'offset' param value of 'or' fn of predicates contract

        // Generationg offset, required by 'or' fn of predicates contract
        // We have two predicates, length of both predicates in 260, so first predicate offset would be 260 and second would be "firstPredicateLength + 260 = 520"
        bytes memory offsetBytes = abi.encodePacked(uint32(gtCalldataLength1 + gtCalldataLength), uint32(gtCalldataLength1));

        // 'or' fn expects offset in uint256, so padding 0s
        for (uint256 i = (32 - offsetBytes.length) / 4; i > 0; i--) {
            offsetBytes = abi.encodePacked(uint32(0), offsetBytes);
        }
        uint256 offset = uint256(bytes32(offsetBytes));

        // Step 8: combine both 'lt' and 'gt' predicates
        bytes memory jointPredicates = abi.encodePacked(
            bytes(gtFnCalldata1),
            bytes(gtFnCalldata)
        );

        // Step 9: Generating 'or' fn calldata
        bytes memory orFnCalldata = abi.encodeWithSignature(
            "or(uint256,bytes)",
            offset,
            jointPredicates
        );

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

        orders[0].c.predicateCalldata = orFnCalldata;
        orders[1].c.predicateCalldata = orFnCalldata;

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

    function testMultiplePredicateANDFail() public {

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
        ); // lt(15, arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress))

        // Helpful in generating bytes offset (see below)
        uint256 ltCalldataLength = bytes(ltFnCalldata).length;
        // console.log("LT Calldata length1 ", ltCalldataLength);

        // Step 4: Generate calldata to send to our target contract (for GT)
        targetContractCalldata = abi.encodeWithSelector(
            usdc_eth.latestAnswer.selector
        );

        // Step 5: Generate predicates contract "arbitrary static call" function calldata (for GT)
        arbitraryStaticCalldata = abi.encodeWithSignature(
            "arbitraryStaticCall(address,bytes)",
            address(usdc_eth),
            targetContractCalldata
        ); // arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress)

        // Step 6: Generate predicates contract "gt" function calldata
        // 18 > 5
        bytes memory gtFnCalldata = abi.encodeWithSignature(
            "gt(uint256,bytes)",
            _oraclePrice(),
            arbitraryStaticCalldata
        );

        // Helpful in generating bytes offset (see below)
        uint256 gtCalldataLength = bytes(gtFnCalldata).length;
        // console.log("GT Calldata length ", gtCalldataLength);

        // Step 7: generate 'offset' param value of 'or' fn of predicates contract

        // Generationg offset, required by 'or' fn of predicates contract
        // We have two predicates, length of both predicates in 260, so first predicate offset would be 260 and second would be "firstPredicateLength + 260 = 520"
        bytes memory offsetBytes = abi.encodePacked(uint32(ltCalldataLength + gtCalldataLength), uint32(ltCalldataLength));

        // 'or' fn expects offset in uint256, so padding 0s
        for (uint256 i = (32 - offsetBytes.length) / 4; i > 0; i--) {
            offsetBytes = abi.encodePacked(uint32(0), offsetBytes);
        }
        uint256 offset = uint256(bytes32(offsetBytes));

        // Step 8: combine both 'lt' and 'gt' predicates
        bytes memory jointPredicates = abi.encodePacked(
            bytes(ltFnCalldata),
            bytes(gtFnCalldata)
        );

        // Step 9: Generating 'or' fn calldata
        bytes memory orFnCalldata = abi.encodeWithSignature(
            "and(uint256,bytes)",
            offset,
            jointPredicates
        );

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

        orders[0].c.predicateCalldata = orFnCalldata;
        orders[1].c.predicateCalldata = orFnCalldata;

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

    function testMultiplePredicateANDFail1() public {

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
        bytes memory gtFnCalldata1 = abi.encodeWithSignature(
            "gt(uint256,bytes)",
            _oraclePrice(),
            arbitraryStaticCalldata
        ); // lt(15, arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress))

        // Helpful in generating bytes offset (see below)
        uint256 gtCalldataLength1 = bytes(gtFnCalldata1).length;
        // console.log("LT Calldata length1 ", ltCalldataLength);

        // Step 4: Generate calldata to send to our target contract (for GT)
        targetContractCalldata = abi.encodeWithSelector(
            usdc_eth.latestAnswer.selector
        );

        // Step 5: Generate predicates contract "arbitrary static call" function calldata (for GT)
        arbitraryStaticCalldata = abi.encodeWithSignature(
            "arbitraryStaticCall(address,bytes)",
            address(usdc_eth),
            targetContractCalldata
        ); // arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress)

        // Step 6: Generate predicates contract "gt" function calldata
        // 18 > 5
        bytes memory gtFnCalldata = abi.encodeWithSignature(
            "gt(uint256,bytes)",
            _oraclePrice(),
            arbitraryStaticCalldata
        );

        // Helpful in generating bytes offset (see below)
        uint256 gtCalldataLength = bytes(gtFnCalldata).length;
        // console.log("GT Calldata length ", gtCalldataLength);

        // Step 7: generate 'offset' param value of 'or' fn of predicates contract

        // Generationg offset, required by 'or' fn of predicates contract
        // We have two predicates, length of both predicates in 260, so first predicate offset would be 260 and second would be "firstPredicateLength + 260 = 520"
        bytes memory offsetBytes = abi.encodePacked(uint32(gtCalldataLength1 + gtCalldataLength), uint32(gtCalldataLength1));

        // 'or' fn expects offset in uint256, so padding 0s
        for (uint256 i = (32 - offsetBytes.length) / 4; i > 0; i--) {
            offsetBytes = abi.encodePacked(uint32(0), offsetBytes);
        }
        uint256 offset = uint256(bytes32(offsetBytes));

        // Step 8: combine both 'lt' and 'gt' predicates
        bytes memory jointPredicates = abi.encodePacked(
            bytes(gtFnCalldata1),
            bytes(gtFnCalldata)
        );

        // Step 9: Generating 'or' fn calldata
        bytes memory orFnCalldata = abi.encodeWithSignature(
            "and(uint256,bytes)",
            offset,
            jointPredicates
        );

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

        orders[0].c.predicateCalldata = orFnCalldata;
        orders[1].c.predicateCalldata = orFnCalldata;

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

    function testMultiplePredicateAND() public {

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
        ); // lt(15, arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress))

        // Helpful in generating bytes offset (see below)
        uint256 ltCalldataLength = bytes(ltFnCalldata).length;
        // console.log("LT Calldata length1 ", ltCalldataLength);

        // Step 4: Generate calldata to send to our target contract (for GT)
        targetContractCalldata = abi.encodeWithSelector(
            usdc_eth.latestAnswer.selector
        );

        // Step 5: Generate predicates contract "arbitrary static call" function calldata (for GT)
        arbitraryStaticCalldata = abi.encodeWithSignature(
            "arbitraryStaticCall(address,bytes)",
            address(usdc_eth),
            targetContractCalldata
        ); // arbitraryStaticCall(targetAddress, callDataToSendToTargetAddress)

        // Step 6: Generate predicates contract "gt" function calldata
        // 18 > 5
        bytes memory ltFnCalldata1 = abi.encodeWithSignature(
            "lt(uint256,bytes)",
            _oraclePrice(),
            arbitraryStaticCalldata
        );

        // Helpful in generating bytes offset (see below)
        uint256 ltCalldataLength1 = bytes(ltFnCalldata1).length;
        // console.log("GT Calldata length ", gtCalldataLength);

        // Step 7: generate 'offset' param value of 'or' fn of predicates contract

        // Generationg offset, required by 'or' fn of predicates contract
        // We have two predicates, length of both predicates in 260, so first predicate offset would be 260 and second would be "firstPredicateLength + 260 = 520"
        bytes memory offsetBytes = abi.encodePacked(uint32(ltCalldataLength + ltCalldataLength1), uint32(ltCalldataLength));

        // 'or' fn expects offset in uint256, so padding 0s
        for (uint256 i = (32 - offsetBytes.length) / 4; i > 0; i--) {
            offsetBytes = abi.encodePacked(uint32(0), offsetBytes);
        }
        uint256 offset = uint256(bytes32(offsetBytes));

        // Step 8: combine both 'lt' and 'gt' predicates
        bytes memory jointPredicates = abi.encodePacked(
            bytes(ltFnCalldata),
            bytes(ltFnCalldata1)
        );

        // Step 9: Generating 'or' fn calldata
        bytes memory orFnCalldata = abi.encodeWithSignature(
            "and(uint256,bytes)",
            offset,
            jointPredicates
        );

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

        orders[0].c.predicateCalldata = orFnCalldata;
        orders[1].c.predicateCalldata = orFnCalldata;

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

    function testPredicate() public {
        uint beforeUsdcMaker2 = usdc.balanceOf(maker2);
        uint beforeWethMaker2 = weth.balanceOf(maker2);
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        uint beforeWethMaker1 = weth.balanceOf(maker1);

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

        orders[0].c.predicateCalldata = ltFnCalldata;
        orders[1].c.predicateCalldata = ltFnCalldata;

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

        uint afterUsdcMaker2 = usdc.balanceOf(maker2);
        uint afterWethMaker2 = weth.balanceOf(maker2);
        uint afterUsdcMaker1 = usdc.balanceOf(maker1);
        uint afterWethMaker1 = weth.balanceOf(maker1);

        assertEq(beforeUsdcMaker2, afterUsdcMaker2 + sellOrder.a.sellTokenAmount);
        assertEq(beforeWethMaker2 + sellOrder.a.buyTokenAmount, afterWethMaker2);
        assertEq(beforeUsdcMaker1 + buyOrder.a.buyTokenAmount, afterUsdcMaker1);
        assertEq(beforeWethMaker1 , afterWethMaker1 + buyOrder.a.sellTokenAmount);
    }

    function testDrain() public {
        vm.deal(address(advancedOrderEngine), 2 ether);
        vm.prank(address(advancedOrderEngine));
        weth.deposit{value: 1 ether}();

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

        bytes memory data = abi.encodeWithSelector(
            usdc.transfer.selector,
            address(33),
            1 ether
        );

        orders[0].c.preInteraction = abi.encodePacked(
            address(advancedOrderEngine),
            data
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker2PrivateKey, _hashTypedDataV4(OrderEngine.hash(sellOrder)));
        bytes memory sellOrderSignature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker1PrivateKey, _hashTypedDataV4(OrderEngine.hash(buyOrder)));
        bytes memory buyOrderSignature = abi.encodePacked(r, s, v);

        signatures[0] = sellOrderSignature;
        signatures[1] = buyOrderSignature;

        vm.expectRevert(InvalidInteractionTarget.selector);
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

    function testDrainERC20() public {

        uint balanceBefore = usdc.balanceOf(operator);

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory order1,
            OrderEngine.Order memory order2,
            OrderEngine.Order memory order3
        ) = getStandardInput1();

        OrderEngine.Order memory order4 = OrderEngine.Order(
            OrderEngine.A (
            127, // nonce value
            block.timestamp + 3600, // valid till
            1000000, // 1 USDC - sell token amount
            2000000, // 0.0048 weth - buy token amount
            0 // fee
            ),
            OrderEngine.B (
            operator, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            operator, // Recipient's Ethereum address
            usdc, // USDC token address - sell token
            usdc // MATIC token address - buy token
            ),
            OrderEngine.C (
            false, // is partially fillable
            "0x", // facilitator calldata 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
            )
        );

        orders = new OrderEngine.Order[](4);

        orders[0] = order3;
        orders[1] = order2;        
        orders[2] = order1;
        orders[3] = order4;

        sell = new uint256[](4);

        sell[0] = order3.a.sellTokenAmount;
        sell[1] = order2.a.sellTokenAmount;        
        sell[2] = order1.a.sellTokenAmount;
        sell[3] = order4.a.sellTokenAmount;

        buy = new uint256[](4);

        buy[0] = order3.a.buyTokenAmount;
        buy[1] = order2.a.buyTokenAmount;        
        buy[2] = order1.a.buyTokenAmount;
        buy[3] = order4.a.buyTokenAmount;

        signatures = new bytes[](4);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker1PrivateKey, _hashTypedDataV4(OrderEngine.hash(order1)));
        bytes memory order1Signature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker2PrivateKey, _hashTypedDataV4(OrderEngine.hash(order2)));
        bytes memory order2Signature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker3PrivateKey, _hashTypedDataV4(OrderEngine.hash(order3)));
        bytes memory order3Signature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(operatorPrivateKey, _hashTypedDataV4(OrderEngine.hash(order4)));
        bytes memory order4Signature = abi.encodePacked(r, s, v);

        signatures[0] = order3Signature;
        signatures[1] = order2Signature;
        signatures[2] = order1Signature;
        signatures[3] = order4Signature;

        vm.expectRevert(SameBuyAndSellToken.selector);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        uint balanceAfter = usdc.balanceOf(operator);

        assertEq(balanceBefore, balanceAfter);

        vm.stopPrank();
    }

    function testAsymetricFillOrKillOrders() public {
        uint beforeUsdcMaker2 = usdc.balanceOf(maker2);
        uint beforeWethMaker2 = weth.balanceOf(maker2);
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        uint beforeWethMaker1 = weth.balanceOf(maker1);
        uint beforeUsdcMaker3 = usdc.balanceOf(maker3);
        uint beforeWethMaker3 = weth.balanceOf(maker3);

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory order1,
            OrderEngine.Order memory order2,
            OrderEngine.Order memory order3
        ) = getStandardInput1();

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
        uint afterUsdcMaker3 = usdc.balanceOf(maker3);
        uint afterWethMaker3 = weth.balanceOf(maker3);

        assertEq(beforeUsdcMaker2, afterUsdcMaker2 + order2.a.sellTokenAmount);
        assertEq(beforeWethMaker2 + order2.a.buyTokenAmount, afterWethMaker2);
        assertEq(beforeUsdcMaker1, afterUsdcMaker1 + order1.a.sellTokenAmount);
        assertEq(beforeWethMaker1 + order1.a.buyTokenAmount, afterWethMaker1);
        assertEq(beforeUsdcMaker3 + order3.a.buyTokenAmount, afterUsdcMaker3);
        assertEq(beforeWethMaker3 , afterWethMaker3 + order3.a.sellTokenAmount);
    }

    function testAsymetricPartiallyFillOrders() public {
        uint beforeUsdcMaker2 = usdc.balanceOf(maker2);
        uint beforeWethMaker2 = weth.balanceOf(maker2);
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        uint beforeWethMaker1 = weth.balanceOf(maker1);
        uint beforeUsdcMaker3 = usdc.balanceOf(maker3);
        uint beforeWethMaker3 = weth.balanceOf(maker3);

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory order1,
            OrderEngine.Order memory order2,
            OrderEngine.Order memory order3
        ) = getStandardInput2();

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
        uint afterUsdcMaker3 = usdc.balanceOf(maker3);
        uint afterWethMaker3 = weth.balanceOf(maker3);

        assertEq(beforeUsdcMaker2, afterUsdcMaker2 + order2.a.sellTokenAmount / 2);
        assertEq(beforeWethMaker2 + order2.a.buyTokenAmount / 2, afterWethMaker2);
        assertEq(beforeUsdcMaker1, afterUsdcMaker1 + order1.a.sellTokenAmount);
        assertEq(beforeWethMaker1 + order1.a.buyTokenAmount, afterWethMaker1);
        assertEq(beforeUsdcMaker3 + order3.a.buyTokenAmount, afterUsdcMaker3);
        assertEq(beforeWethMaker3 , afterWethMaker3 + order3.a.sellTokenAmount);
    }

    function testFacilatatorBorrowedAmounts() public {

        uint balanceBefore = usdc.balanceOf(operator);
        uint beforeUsdcMaker2 = usdc.balanceOf(maker2);
        uint beforeWethMaker2 = weth.balanceOf(maker2);
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        uint beforeWethMaker1 = weth.balanceOf(maker1);
        uint beforeUsdcMaker3 = usdc.balanceOf(maker3);
        uint beforeWethMaker3 = weth.balanceOf(maker3);

        vm.startPrank(operator);

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory order1,
            OrderEngine.Order memory order2,
            OrderEngine.Order memory order3
        ) = getStandardInput1();

        facilitatorInteraction = abi.encodePacked(
            helper
        );
        borrowedAmounts = new uint256[](1);
        borrowedAmounts[0] = 1000000;
        borrowedTokens = new IERC20[](1);
        borrowedTokens[0] = usdc;

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
        uint afterUsdcMaker3 = usdc.balanceOf(maker3);
        uint afterWethMaker3 = weth.balanceOf(maker3);

        assertEq(beforeUsdcMaker2, afterUsdcMaker2 + order2.a.sellTokenAmount);
        assertEq(beforeWethMaker2 + order2.a.buyTokenAmount, afterWethMaker2);
        assertEq(beforeUsdcMaker1, afterUsdcMaker1 + order1.a.sellTokenAmount);
        assertEq(beforeWethMaker1 + order1.a.buyTokenAmount, afterWethMaker1);
        assertEq(beforeUsdcMaker3 + order3.a.buyTokenAmount, afterUsdcMaker3);
        assertEq(beforeWethMaker3 , afterWethMaker3 + order3.a.sellTokenAmount);

        uint balanceAfter = usdc.balanceOf(operator);

        assertEq(balanceBefore + 1 * 10 ** 6, balanceAfter);
    }

    function testCancelOrders() public {

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory buyOrder,
        ) = getStandardInput();

        vm.prank(maker1);
        advancedOrderEngine.cancelOrder(buyOrder);

        vm.startPrank(operator);
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

    function testCancelOrdersFail() public {

        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts,
            OrderEngine.Order memory buyOrder,
        ) = getStandardInput();

        vm.startPrank(operator);

        vm.expectRevert(AccessDenied.selector);
        advancedOrderEngine.cancelOrder(buyOrder);

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

        vm.startPrank(maker1);

        vm.expectRevert(OrderFilledAlready.selector);
        advancedOrderEngine.cancelOrder(buyOrder);
        vm.stopPrank();
    }

    function testSingleOrder() public {
        // This is an invalid test case, i.e this is not a real word use case, this was only used to determine working of pre intercation code
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        // uint beforeWethMaker1 = weth.balanceOf(maker1);

        OrderEngine.Order[] memory orders;
        uint256[] memory sell;
        uint256[] memory buy;
        bytes[] memory signatures;
        bytes memory facilitatorInteraction;
        IERC20[] memory borrowedTokens;
        uint256[] memory borrowedAmounts;
        OrderEngine.Order memory sellOrder = OrderEngine.Order(
            OrderEngine.A (
            123, // nonce value
            block.timestamp + 3600, // valid till
            1, //  weth - sell token // so it does not fail on zero amount
            10000000, // 10 USDC - buy amount
            0 // fee
            ),
            OrderEngine.B (
            maker1, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            maker1, // Recipient's Ethereum address
            weth, // weth token address - sell token
            usdc // USDC token address - buy token
            ),
            OrderEngine.C (
            true, // is partially fillable
            "0x", // facilitator call data 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
            )
        );

        uint amountIn = qouter.quoteExactOutputSingle(
            address(weth),
            address(usdc),
            500,
            sellOrder.a.buyTokenAmount,
            0
        );

        vm.prank(maker1);
        weth.transfer(swapper, amountIn);

        bytes memory data = abi.encodePacked(
            swapper,
            abi.encodeWithSelector(
                swapRouter02.exactInputSingle.selector,
                ISwapRouter02.ExactInputSingleParams (
                    address(weth),
                    address(usdc),
                    500,
                    address(advancedOrderEngine),
                    amountIn,
                    sellOrder.a.buyTokenAmount,
                    0
                )
            )
        );

        sellOrder.c.preInteraction = data;
        // sellOrder.a.sellTokenAmount = amountIn;

        orders = new OrderEngine.Order[](1);

        orders[0] = sellOrder;

        sell = new uint256[](1);

        sell[0] = sellOrder.a.sellTokenAmount;

        buy = new uint256[](1);

        buy[0] = sellOrder.a.buyTokenAmount;

        signatures = new bytes[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker1PrivateKey, _hashTypedDataV4(OrderEngine.hash(sellOrder)));
        bytes memory sellOrderSignature = abi.encodePacked(r, s, v);

        signatures[0] = sellOrderSignature;

        facilitatorInteraction = "0x";
        borrowedAmounts = new uint256[](0);
        borrowedTokens = new IERC20[](0);

        vm.startPrank(operator);

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

        uint afterUsdcMaker1 = usdc.balanceOf(maker1);
        // uint afterWethMaker1 = weth.balanceOf(maker1);
        assertEq(beforeUsdcMaker1 + sellOrder.a.buyTokenAmount, afterUsdcMaker1);
        // assertEq(beforeWethMaker1, afterWethMaker1);
    }

    function testFacilitatorSwap() public {
        uint beforeUsdcMaker1 = usdc.balanceOf(maker1);
        uint beforeWethMaker1 = weth.balanceOf(maker1);

        (
        OrderEngine.Order[] memory orders,
        uint256[] memory sell,
        uint256[] memory buy,
        bytes[] memory signatures,
        bytes memory facilitatorInteraction,
        IERC20[] memory borrowedTokens,
        uint256[] memory borrowedAmounts,
        OrderEngine.Order memory order1,
        ) = getStandardInput3();

        vm.startPrank(operator);

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

        uint afterUsdcMaker1 = usdc.balanceOf(maker1);
        uint afterWethMaker1 = weth.balanceOf(maker1);
        assertEq(beforeUsdcMaker1, afterUsdcMaker1 + order1.a.sellTokenAmount);
        assertEq(beforeWethMaker1 + order1.a.buyTokenAmount, afterWethMaker1);
    }

    function getOrder1() private view returns(OrderEngine.Order memory) {
        return OrderEngine.Order(
            OrderEngine.A (
            123, // nonce value
            block.timestamp + 3600, // valid till
            4800000000000000, // 0.0048 weth - sell token
            10000000, // 10 USDC - buy amount
            0 // fee
            ),
            OrderEngine.B (
            maker1, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            maker1, // Recipient's Ethereum address
            weth, // MATIC token address - sell token
            usdc // USDC token address - buy token
            ),
            OrderEngine.C (
            true, // is partially fillable
            "0x", // facilitator call data 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
            )
        );
    }

    function getOrder2() private view returns(OrderEngine.Order memory) {
        return OrderEngine.Order(
            OrderEngine.A (
            124, // nonce value
            block.timestamp + 3600, // valid till
            10000000, // 10 USDC - sell token amount
            4800000000000000, // 0.0048 weth - buy token amount
            0 // fee
            ),
            OrderEngine.B (
            maker2, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            maker2, // Recipient's Ethereum address
            usdc, // USDC token address - sell token
            weth // MATIC token address - buy token
            ),
            OrderEngine.C (
            true, // is partially fillable
            "0x", // facilitator calldata 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
            )
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
        OrderEngine.Order memory order1,
        OrderEngine.Order memory order2
    ) {

        order1 = getOrder1();
        order2 = getOrder2();

        orders = new OrderEngine.Order[](2);

        orders[0] = order2;
        orders[1] = order1;

        sell = new uint256[](2);

        sell[0] = order2.a.sellTokenAmount;
        sell[1] = order1.a.sellTokenAmount;

        buy = new uint256[](2);

        buy[0] = order2.a.buyTokenAmount;
        buy[1] = order1.a.buyTokenAmount;

        signatures = new bytes[](2);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker2PrivateKey, _hashTypedDataV4(OrderEngine.hash(order2)));
        bytes memory sellOrderSignature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker1PrivateKey, _hashTypedDataV4(OrderEngine.hash(order1)));
        bytes memory buyOrderSignature = abi.encodePacked(r, s, v);

        signatures[0] = sellOrderSignature;
        signatures[1] = buyOrderSignature;

        facilitatorInteraction = "0x";
        borrowedAmounts = new uint256[](0);
        borrowedTokens = new IERC20[](0);
    }

    function getStandardInput1() private view returns(
        OrderEngine.Order[] memory orders,
        uint256[] memory sell,
        uint256[] memory buy,
        bytes[] memory signatures,
        bytes memory facilitatorInteraction,
        IERC20[] memory borrowedTokens,
        uint256[] memory borrowedAmounts,
        OrderEngine.Order memory order1,
        OrderEngine.Order memory order2,
        OrderEngine.Order memory order3
    ) {

        order1 = OrderEngine.Order(
            OrderEngine.A (
            124, // nonce value
            block.timestamp + 3600, // valid till
            10000000, // 10 USDC - sell token amount
            4800000000000000, // 0.0048 weth - buy token amount
            0 // fee
            ),
            OrderEngine.B (
            maker1, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            maker1, // Recipient's Ethereum address
            usdc, // USDC token address - sell token
            weth // MATIC token address - buy token
            ),
            OrderEngine.C (
            false, // is partially fillable
            "0x", // facilitator calldata 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
            )
        );

        order2 = OrderEngine.Order(
            OrderEngine.A (
            125, // nonce value
            block.timestamp + 3600, // valid till
            11000000, // 11 USDC - sell token amount
            4800000000000000, // 0.0048 weth - buy token amount
            0 // fee
            ),
            OrderEngine.B (
            maker2, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            maker2, // Recipient's Ethereum address
            usdc, // USDC token address - sell token
            weth // MATIC token address - buy token
            ),
            OrderEngine.C (
            false, // is partially fillable
            "0x", // facilitator calldata 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
            )
        );

        order3 = OrderEngine.Order(
            OrderEngine.A (
            126, // nonce value
            block.timestamp + 3600, // valid till
            0.0096 ether, // 0.0048 weth - sell token amount
            20000000, // 20 USDC - buy token amount
            0 // fee
            ),
            OrderEngine.B (
            maker3, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            maker3, // Recipient's Ethereum address
            weth, // MATIC token address - sell token
            usdc // USDC token address - buy token
            ),
            OrderEngine.C (
            false, // is partially fillable
            "0x", // facilitator calldata 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
            )
        );

        orders = new OrderEngine.Order[](3);

        orders[0] = order3;
        orders[1] = order2;        
        orders[2] = order1;

        sell = new uint256[](3);

        sell[0] = order3.a.sellTokenAmount;
        sell[1] = order2.a.sellTokenAmount;        
        sell[2] = order1.a.sellTokenAmount;

        buy = new uint256[](3);

        buy[0] = order3.a.buyTokenAmount;
        buy[1] = order2.a.buyTokenAmount;        
        buy[2] = order1.a.buyTokenAmount;

        signatures = new bytes[](3);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker1PrivateKey, _hashTypedDataV4(OrderEngine.hash(order1)));
        bytes memory order1Signature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker2PrivateKey, _hashTypedDataV4(OrderEngine.hash(order2)));
        bytes memory order2Signature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker3PrivateKey, _hashTypedDataV4(OrderEngine.hash(order3)));
        bytes memory order3Signature = abi.encodePacked(r, s, v);

        signatures[0] = order3Signature;
        signatures[1] = order2Signature;
        signatures[2] = order1Signature;

        facilitatorInteraction = "0x";
        borrowedAmounts = new uint256[](0);
        borrowedTokens = new IERC20[](0);
    }

    function getStandardInput2() private view returns(
        OrderEngine.Order[] memory orders,
        uint256[] memory sell,
        uint256[] memory buy,
        bytes[] memory signatures,
        bytes memory facilitatorInteraction,
        IERC20[] memory borrowedTokens,
        uint256[] memory borrowedAmounts,
        OrderEngine.Order memory order1,
        OrderEngine.Order memory order2,
        OrderEngine.Order memory order3
    ) {

        order1 = OrderEngine.Order(
            OrderEngine.A (
            124, // nonce value
            block.timestamp + 3600, // valid till
            10000000, // 10 USDC - sell token amount
            4800000000000000, // 0.0048 weth - buy token amount
            0 // fee
            ),
            OrderEngine.B (
            maker1, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            maker1, // Recipient's Ethereum address
            usdc, // USDC token address - sell token
            weth // MATIC token address - buy token
            ),
            OrderEngine.C (
            false, // is partially fillable
            "0x", // facilitator calldata 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
            )
        );

        order2 = OrderEngine.Order(
            OrderEngine.A (
            125, // nonce value
            block.timestamp + 3600, // valid till
            10000000, // 11 USDC - sell token amount
            4800000000000000, // 0.0048 weth - buy token amount
            0 // fee
            ),
            OrderEngine.B (
            maker2, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            maker2, // Recipient's Ethereum address
            usdc, // USDC token address - sell token
            weth // MATIC token address - buy token
            ),
            OrderEngine.C (
            true, // is partially fillable
            "0x", // facilitator calldata 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
            )
        );

        order3 = OrderEngine.Order(
            OrderEngine.A (
            126, // nonce value
            block.timestamp + 3600, // valid till
            0.0072 ether, // 0.0048 weth - sell token amount
            15000000, // 20 USDC - buy token amount
            0 // fee
            ),
            OrderEngine.B (
            maker3, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            maker3, // Recipient's Ethereum address
            weth, // MATIC token address - sell token
            usdc // USDC token address - buy token
            ),
            OrderEngine.C (
            false, // is partially fillable
            "0x", // facilitator calldata 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
            )
        );

        orders = new OrderEngine.Order[](3);

        orders[0] = order3;
        orders[1] = order2;        
        orders[2] = order1;

        sell = new uint256[](3);

        sell[0] = order3.a.sellTokenAmount;
        sell[1] = order2.a.sellTokenAmount / 2;        
        sell[2] = order1.a.sellTokenAmount;

        buy = new uint256[](3);

        buy[0] = order3.a.buyTokenAmount;
        buy[1] = order2.a.buyTokenAmount / 2;        
        buy[2] = order1.a.buyTokenAmount;

        signatures = new bytes[](3);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker1PrivateKey, _hashTypedDataV4(OrderEngine.hash(order1)));
        bytes memory order1Signature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker2PrivateKey, _hashTypedDataV4(OrderEngine.hash(order2)));
        bytes memory order2Signature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker3PrivateKey, _hashTypedDataV4(OrderEngine.hash(order3)));
        bytes memory order3Signature = abi.encodePacked(r, s, v);

        signatures[0] = order3Signature;
        signatures[1] = order2Signature;
        signatures[2] = order1Signature;

        facilitatorInteraction = "0x";
        borrowedAmounts = new uint256[](0);
        borrowedTokens = new IERC20[](0);
    }

    function getStandardInput3() private returns(
        OrderEngine.Order[] memory orders,
        uint256[] memory sell,
        uint256[] memory buy,
        bytes[] memory signatures,
        bytes memory facilitatorInteraction,
        IERC20[] memory borrowedTokens,
        uint256[] memory borrowedAmounts,
        OrderEngine.Order memory order1,
        bytes memory data
        // OrderEngine.Order memory order2,
        // OrderEngine.Order memory order3
    ) {
        uint amountOut = qouter.quoteExactInputSingle(
            address(usdc),
            address(weth),
            500,
            10000000,
            0
        );

        order1 = OrderEngine.Order(
            OrderEngine.A (
            124, // nonce value
            block.timestamp + 3600, // valid till
            10000000, // 10 USDC - sell token amount
            amountOut, // 0.0048 weth - buy token amount
            0 // fee
            ),
            OrderEngine.B (
            maker1, // Maker's address
            operator, // Taker's Ethereum address (or null for public order)
            maker1, // Recipient's Ethereum address
            usdc, // USDC token address - sell token
            weth // MATIC token address - buy token
            ),
            OrderEngine.C (
            false, // is partially fillable
            "0x", // facilitator calldata 
            "", // predicate calldata 
            "0x", // pre-interaction data 
            "0x" // post-interaction data 
            )
        );

        address fs = address(new FacilitatorSwap());
        FacilitatorSwap(fs).approve(address(usdc), address(swapRouter02), UINT256_MAX);

        data = abi.encodePacked(
            fs,
            abi.encodeWithSelector(
                swapRouter02.exactInputSingle.selector,
                ISwapRouter02.ExactInputSingleParams (
                    address(usdc),
                    address(weth),
                    500,
                    address(advancedOrderEngine),
                    order1.a.sellTokenAmount,
                    amountOut,
                    0
                )
            )
        );

        orders = new OrderEngine.Order[](1);

        orders[0] = order1;

        sell = new uint256[](1);

        sell[0] = order1.a.sellTokenAmount;

        buy = new uint256[](1);

        buy[0] = order1.a.buyTokenAmount;

        signatures = new bytes[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker1PrivateKey, _hashTypedDataV4(OrderEngine.hash(order1)));
        bytes memory order1Signature = abi.encodePacked(r, s, v);

        signatures[0] = order1Signature;

        facilitatorInteraction = data;
        borrowedAmounts = new uint256[](1);
        borrowedAmounts[0] = order1.a.sellTokenAmount;

        borrowedTokens = new IERC20[](1);
        borrowedTokens[0] = usdc;

    }

    function getStandardInput4() private view returns(
        OrderEngine.Order[] memory orders,
        uint256[] memory sell,
        uint256[] memory buy,
        bytes[] memory signatures,
        bytes memory facilitatorInteraction,
        IERC20[] memory borrowedTokens,
        uint256[] memory borrowedAmounts,
        OrderEngine.Order memory order1,
        OrderEngine.Order memory order2,
        OrderEngine.Order memory order3
    ) {

        order1 = OrderEngine.Order(
            OrderEngine.A(
                124, // nonce value
                block.timestamp + 3600, // valid till
                10000000, // 10 USDC - sell token amount
                4800000000000000, // 0.0048 weth - buy token amount
                0 // fee
            ),
            OrderEngine.B(
                maker1, // Maker's address
                operator, // Taker's Ethereum address (or null for public order)
                maker1, // Recipient's Ethereum address
                usdc, // USDC token address - sell token
                weth // MATIC token address - buy token
            ),
            OrderEngine.C(
                false, // is partially fillable
                "0x", // facilitator calldata 
                "", // predicate calldata 
                "0x", // pre-interaction data 
                "0x" // post-interaction data
            ) 
        );

        order2 = OrderEngine.Order(
            OrderEngine.A(
                125, // nonce value
                block.timestamp + 3600, // valid till
                4800000000000000, // 0.0048 weth - sell token amount
                13 ether, // 13 matic - sell token amount
                0 // fee
            ),
            OrderEngine.B(
                maker2, // Maker's address
                operator, // Taker's Ethereum address (or null for public order)
                maker2, // Recipient's Ethereum address
                weth, // MATIC token address - sell token
                wmatic // USDC token address - buy token
            ),
            OrderEngine.C(
                false, // is partially fillable
                "0x", // facilitator calldata 
                "", // predicate calldata 
                "0x", // pre-interaction data 
                "0x" // post-interaction data
            ) 
        );

        order3 = OrderEngine.Order(
            OrderEngine.A(
                126, // nonce value
                block.timestamp + 3600, // valid till
                13 ether, // 0.0048 weth - sell token amount
                10000000, // 20 USDC - buy token amount
                0 // fee
            ),
            OrderEngine.B(
                maker3, // Maker's address
                operator, // Taker's Ethereum address (or null for public order)
                maker3, // Recipient's Ethereum address
                wmatic, // MATIC token address - sell token
                usdc // USDC token address - buy token
            ),
            OrderEngine.C(
                false, // is partially fillable
                "0x", // facilitator calldata 
                "", // predicate calldata 
                "0x", // pre-interaction data 
                "0x" // post-interaction data
            ) 
        );

        orders = new OrderEngine.Order[](3);

        orders[0] = order3;
        orders[1] = order2;        
        orders[2] = order1;

        sell = new uint256[](3);

        sell[0] = order3.a.sellTokenAmount;
        sell[1] = order2.a.sellTokenAmount;        
        sell[2] = order1.a.sellTokenAmount;

        buy = new uint256[](3);

        buy[0] = order3.a.buyTokenAmount;
        buy[1] = order2.a.buyTokenAmount;       
        buy[2] = order1.a.buyTokenAmount;

        signatures = new bytes[](3);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker1PrivateKey, _hashTypedDataV4(OrderEngine.hash(order1)));
        bytes memory order1Signature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker2PrivateKey, _hashTypedDataV4(OrderEngine.hash(order2)));
        bytes memory order2Signature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(maker3PrivateKey, _hashTypedDataV4(OrderEngine.hash(order3)));
        bytes memory order3Signature = abi.encodePacked(r, s, v);

        signatures[0] = order3Signature;
        signatures[1] = order2Signature;
        signatures[2] = order1Signature;

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