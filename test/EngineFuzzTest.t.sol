// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";
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

contract EngineFuzzTest is Test {
    Predicates predicates;
    AdvancedOrderEngine advancedOrderEngine;
    GenerateCalldata generateCalldata;
    address helper;
    address swapper;
    IERC20 wmatic = IERC20(0x7c9f4C87d911613Fe9ca58b579f737911AAD2D43);
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IWETH9 weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 wbtc = IERC20(0x9Ee1Aa18F3FEB435f811d6AE2F71B7D2a4Adce0B);
    ISwapRouter02 swapRouter02 =
        ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    IPriceFeed usdc_eth =
        IPriceFeed(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
    IQuoter qouter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    IQuoter positions = IQuoter(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address zeroAddress = address(0);
    address feeCollector = address(147578);
    address admin = address(3);
    uint256 maker1PrivateKey =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address maker1 = vm.addr(maker1PrivateKey);
    uint256 maker2PrivateKey =
        0xac0974bec39a17e36ba4a6b4d233ff944bacb478cbed5efcae784d7bf4f2ff80;
    address maker2 = vm.addr(maker2PrivateKey);
    uint256 maker3PrivateKey =
        0xac0974bec38a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address maker3 = vm.addr(maker3PrivateKey);
    uint256 operatorPrivateKey = 0xB0B;
    address operator = vm.addr(operatorPrivateKey);

    function setUp() public {
        vm.startPrank(admin);

        predicates = new Predicates();
        generateCalldata = new GenerateCalldata(address(predicates));
        advancedOrderEngine = new AdvancedOrderEngine(
            IPredicates(address(predicates)),
            feeCollector
        );
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

        vm.deal(maker1, 20000000 ether);
        vm.deal(maker2, 20000000 ether);
        vm.deal(maker3, 20000000 ether);
        vm.deal(operator, 20000000 ether);
        vm.deal(admin, 20000000 ether);

        vm.stopPrank();

        vm.startPrank(maker1);

        weth.approve(address(swapRouter02), UINT256_MAX);
        weth.approve(address(advancedOrderEngine), UINT256_MAX);

        // get weth
        weth.deposit{value: 10000000 ether}();

        usdc.approve(address(swapRouter02), UINT256_MAX);
        usdc.approve(address(advancedOrderEngine), UINT256_MAX);

        // get usdc
        swapRouter02.exactInputSingle{value: 1000000 ether}(
            ISwapRouter02.ExactInputSingleParams(
                address(weth),
                address(usdc),
                500,
                maker1,
                20 ether,
                0,
                0
            )
        );

        console.log(
            "Maker 1 - USDC Balance:",
            usdc.balanceOf(address(maker1)) / 1000000
        );

        vm.stopPrank();

        vm.startPrank(maker2);

        weth.approve(address(swapRouter02), UINT256_MAX);
        weth.approve(address(advancedOrderEngine), UINT256_MAX);

        // get weth
        weth.deposit{value: 10000000 ether}();

        usdc.approve(address(swapRouter02), UINT256_MAX);
        usdc.approve(address(advancedOrderEngine), UINT256_MAX);

        // get usdc
        swapRouter02.exactInputSingle{value: 1000000 ether}(
            ISwapRouter02.ExactInputSingleParams(
                address(weth),
                address(usdc),
                500,
                maker2,
                20 ether,
                0,
                0
            )
        );

        console.log(
            "Maker 2 Balance - USDC:",
            usdc.balanceOf(maker2) / 1000000
        );

        vm.stopPrank();

        vm.startPrank(maker3);

        weth.approve(address(swapRouter02), UINT256_MAX);
        weth.approve(address(advancedOrderEngine), UINT256_MAX);

        // get weth
        weth.deposit{value: 20 ether}();

        usdc.approve(address(swapRouter02), UINT256_MAX);
        usdc.approve(address(advancedOrderEngine), UINT256_MAX);

        // get usdc
        swapRouter02.exactInputSingle{value: 20 ether}(
            ISwapRouter02.ExactInputSingleParams(
                address(weth),
                address(usdc),
                500,
                maker3,
                20 ether,
                0,
                0
            )
        );
        console.log(
            "Maker 23 Balance - USDC:",
            usdc.balanceOf(maker3) / 1000000
        );

        wmatic.approve(address(swapRouter02), UINT256_MAX);
        wmatic.approve(address(advancedOrderEngine), UINT256_MAX);

        // get matic
        swapRouter02.exactInputSingle{value: 20 ether}(
            ISwapRouter02.ExactInputSingleParams(
                address(weth),
                address(wmatic),
                3000,
                maker3,
                20 ether,
                0,
                0
            )
        );

        vm.stopPrank();

        vm.startPrank(operator);

        weth.approve(address(swapRouter02), UINT256_MAX);
        weth.approve(address(advancedOrderEngine), UINT256_MAX);

        // get weth
        weth.deposit{value: 20 ether}();

        usdc.approve(address(swapRouter02), UINT256_MAX);
        usdc.approve(address(advancedOrderEngine), UINT256_MAX);

        // get usdc
        swapRouter02.exactInputSingle{value: 20 ether}(
            ISwapRouter02.ExactInputSingleParams(
                address(weth),
                address(usdc),
                500,
                operator,
                20 ether,
                0,
                0
            )
        );

        // usdc.transfer(address(advancedOrderEngine), 100000000);

        vm.stopPrank();
    }

    function testFuzz(uint256 buy_qty, uint256 sell_qty) public {
        vm.assume(buy_qty > 0 && sell_qty > 0);

        uint256 maker1WETHBalance = weth.balanceOf(address(maker1));
        uint256 maker1USDCBalance = usdc.balanceOf(address(maker1));

        uint256 maker2WETHBalance = weth.balanceOf(address(maker2));
        uint256 maker2USDCBalance = usdc.balanceOf(address(maker2));

        console.log("make1 WETH Balance:", maker1WETHBalance);
        console.log("make2 WETH Balance:", maker2WETHBalance);

        console.log("make1 USDC Balance:", maker1USDCBalance);
        console.log("make2 USDC Balance:", maker2USDCBalance);

        console.log("buy_qty:", buy_qty);
        console.log("sell_qty:", sell_qty);

        // require(buy_qty <= maker1USDCBalance && buy_qty <= maker2USDCBalance && buy_qty <= maker1WETHBalance && buy_qty <= maker2WETHBalance, "Buy quantity exceeds balance");
        // require(sell_qty <= maker1USDCBalance && sell_qty <= maker2USDCBalance && sell_qty <= maker1WETHBalance && sell_qty <= maker2WETHBalance, "Sell quantity exceeds balance");

        // 1000000000000000000 > 10000000000000000000000000 || 1 > 46984
        if (buy_qty * 1 ether > maker1WETHBalance || buy_qty * 1000000 > maker2USDCBalance){
            vm.expectRevert();}
        // 46988000000 > 46987799359 || 46988000000000000000000 > 10000000000000000000000000
        if (sell_qty * 1000000 > maker1USDCBalance || sell_qty * 1 ether> maker2WETHBalance){
            vm.expectRevert();}
            
    

        vm.startPrank(operator);

        //OrderEngine.Order[] memory orders;
        (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts
        ) = orderInput(buy_qty, sell_qty);

        // Calculate total sell and buy amounts for each token
    uint256 totalSellWETH = 0;
    uint256 totalBuyWETH = 0;
    uint256 totalSellUSDC = 0;
    uint256 totalBuyUSDC = 0;

    for (uint i = 0; i < orders.length; i++) {
        if (address(orders[i].sellToken) == address(weth)) {
            totalSellWETH += sell[i];
            totalBuyUSDC += buy[i];
        } else if (address(orders[i].sellToken) == address(usdc)) {
            totalSellUSDC += sell[i];
            totalBuyWETH += buy[i];
        }
    }
    if (totalSellWETH != totalBuyWETH && totalSellUSDC != totalBuyUSDC){
        vm.expectRevert();

    }
    


        //require(orders.length >= 2);
        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            signatures,
            facilitatorInteraction,
            borrowedTokens,
            borrowedAmounts
        );

        uint256 vaultbal = usdc.balanceOf(address(advancedOrderEngine));
        console.log("Vault Balance:", vaultbal);

        assert(vaultbal == 0);

        vm.stopPrank();
    }

    function orderInput(
        uint256 buy_qty,
        uint256 sell_qty) private returns (
            OrderEngine.Order[] memory orders,
            uint256[] memory sell,
            uint256[] memory buy,
            bytes[] memory signatures,
            bytes memory facilitatorInteraction,
            IERC20[] memory borrowedTokens,
            uint256[] memory borrowedAmounts){
        uint size = determineOrderSize(); // Function to determine a safe number of orders
        borrowedAmounts = new uint256[](0);
        borrowedTokens = new IERC20[](0);
        facilitatorInteraction = "0x";
        orders = new OrderEngine.Order[](size * 2); // times 2 to accommodate both sell and buy orders
        sell = new uint256[](size * 2);
        buy = new uint256[](size * 2);
        signatures = new bytes[](size * 2);

        // OrderEngine.Order memory order1 = getOrder1();
        // orders[0] = order1;
        // sell[0] = order1.sellTokenAmount;
        // buy[0] = order1.buyTokenAmount;
        // signatures[0] = signOrder(orders[0], maker1PrivateKey);

        for (uint i = 0; i < size; i++) {
            // Creating a sell order
            (uint256 sellAmount, uint256 buyAmount) = getRandomOrderAmounts(
                maker1,
                maker2,
                weth,
                usdc,
                buy_qty,
                sell_qty
            );
            orders[i] = createOrder(
                i,
                sellAmount,
                buyAmount,
                maker1,
                weth,
                usdc
            );
            sell[i] = sellAmount;
            buy[i] = buyAmount;
            signatures[i] = signOrder(orders[i], maker1PrivateKey);

            // Creating a corresponding buy order
            (sellAmount, buyAmount) = getRandomOrderAmounts(
                maker2,
                maker1,
                usdc,
                weth,
                buy_qty,
                sell_qty
            );
            orders[size + i] = createOrder(
                size + i,
                sellAmount,
                buyAmount,
                maker2,
                usdc,
                weth
            );
            sell[size + i] = sellAmount;
            buy[size + i] = buyAmount;
            signatures[size + i] = signOrder(
                orders[size + i],
                maker2PrivateKey
            );
            // printOrder(orders[i]);
            // printOrder(orders[i+size]);
        }

        
        
        

    }

    function createOrder(
        uint nonce,
        uint256 sellAmount,
        uint256 buyAmount,
        address maker,
        IERC20 sellToken,
        IERC20 buyToken
    ) private view returns (OrderEngine.Order memory) {
        return
            OrderEngine.Order(
                nonce,
                block.timestamp + 9000,
                sellAmount,
                buyAmount,
                0, // fee
                maker,
                operator,
                maker,
                sellToken,
                buyToken,
                true, // is partially fillable
                "0x", // facilitator call data
                "", // predicate calldata
                "0x", // pre-interaction data
                "0x" // post-interaction data
            );
}

    function signOrder(
        OrderEngine.Order memory order,
        uint256 privateKey) private view returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            _hashTypedDataV4(OrderEngine.hash(order))
        );
        return abi.encodePacked(r, s, v);}

    
    function determineOrderSize() private view returns (uint) {
        uint256 blockGasLimit = block.gaslimit; // Get the current block gas limit
        uint256 estimatedGasPerTransaction = 21000; // Estimate gas per transaction (adjust as needed)
        //return 5; // Calculate the safe number of orders
        return 1000;
    }

    function getRandomOrderAmounts(
        address maker1,
        address maker2,
        IERC20 sellToken,
        IERC20 buyToken,
        uint256 buy_qty,
        uint256 sell_qty
    ) private view returns (uint256, uint256) {
        uint256 sellAmount;
        uint256 buyAmount;

        // If the sellToken is WETH, set sellAmount to 1 ether, else to 2,200,000,000 (assumed USDC)
        if (address(sellToken) == address(weth)) {
            sellAmount = buy_qty * 1 ether;
        } else {
            sellAmount = buy_qty * 1000000;
        }

        // If the buyToken is WETH, set buyAmount to 1 ether, else to 2,200,000,000 (assumed USDC)
        if (address(buyToken) == address(weth)) {
            buyAmount = sell_qty * 1 ether;
        } else {
            buyAmount = sell_qty * 1000000;
        }

        return (sellAmount, buyAmount);
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty))
            );
    }

    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        return
            ECDSA.toTypedDataHash(
                advancedOrderEngine.DOMAIN_SEPARATOR(),
                structHash
            );
    }

    function getOrder1() private view returns (OrderEngine.Order memory) {
        return
            OrderEngine.Order(
                0, // nonce value
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

    function printOrder(OrderEngine.Order memory order) internal view {
        console2.log("order: ");
        console2.log(order.nonce);
        console2.log(order.validTill);
        console2.log(order.sellTokenAmount);
        console2.log(order.buyTokenAmount);
        console2.log(order.feeAmounts);
        console2.log(order.maker);
        console2.log(order.operator);
        console2.log(order.recipient);
        console2.log(address(order.sellToken));
        console2.log(address(order.buyToken));
        console2.log(order.isPartiallyFillable);
        console2.logBytes32(order.extraData);
        console2.logBytes(order.predicateCalldata);
        console2.logBytes(order.preInteraction);
        console2.logBytes(order.postInteraction);
    }
}
