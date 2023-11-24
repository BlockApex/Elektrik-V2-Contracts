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
    address zeroAddress = address(0);
    address feeCollector = address(147578);
    address admin = address(3);
    uint256 makerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; //also owner of contract
    address maker = vm.addr(makerPrivateKey);
    uint256 operatorPrivateKey = 0xB0B; //also owner of contract
    address operator = vm.addr(makerPrivateKey);


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

        vm.deal(maker, 20 ether);
        vm.deal(operator, 20 ether);
        vm.deal(admin, 20 ether);
    
        vm.stopPrank();

        vm.startPrank(maker);

        weth.approve(address(swapRouter02), UINT256_MAX);
        weth.approve(address(advancedOrderEngine), UINT256_MAX);
        usdc.approve(address(swapRouter02), UINT256_MAX);
        usdc.approve(address(advancedOrderEngine), UINT256_MAX);
        // weth.approve(address(swapRouter02), UINT256_MAX);

        // get usdc
        swapRouter02.exactInputSingle{value: 1 ether}(
            ISwapRouter02.ExactInputSingleParams (
                address(weth),
                address(usdc),
                500,
                maker,
                1 ether,
                0,
                0
            )
        );

        IWETH9(address(weth)).deposit{value: 1 ether}();

        // // get matic
        // swapRouter02.exactInputSingle{value: 1 ether}(
        //     ISwapRouter02.ExactInputSingleParams (
        //         address(weth),
        //         address(wmatic),
        //         3000,
        //         maker,
        //         1 ether,
        //         0,
        //         0
        //     )
        // );

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
        bytes memory facilitatorInteraction = '0x';
        console2.log(facilitatorInteraction.length);

        OrderEngine.Order memory buyOrder = getDummyBuyOrder();
        OrderEngine.Order memory sellOrder = getDummySellOrder();

        vm.startPrank(operator);

        OrderEngine.Order[] memory orders = new OrderEngine.Order[](2);

        orders[0] = sellOrder;
        orders[1] = buyOrder;

        uint256[] memory sell = new uint256[](2);

        sell[0] = sellOrder.sellTokenAmount;
        sell[1] = buyOrder.sellTokenAmount;

        uint256[] memory buy = new uint256[](2);

        buy[0] = sellOrder.buyTokenAmount;
        buy[1] = buyOrder.buyTokenAmount;

        bytes[] memory sigs = new bytes[](2);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(makerPrivateKey, _hashTypedDataV4(OrderEngine.hash(sellOrder)));
        bytes memory sellOrderSignature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(makerPrivateKey, _hashTypedDataV4(OrderEngine.hash(buyOrder)));
        bytes memory buyOrderSignature = abi.encodePacked(r, s, v);

        sigs[0] = sellOrderSignature;
        sigs[1] = buyOrderSignature;

        uint256[] memory emptyArray2 = new uint256[](0);
        IERC20[] memory emptyArray1 = new IERC20[](0);

        advancedOrderEngine.fillOrders(
            orders,
            sell,
            buy,
            sigs,
            '0x',
            emptyArray1,
            emptyArray2
        );

        vm.stopPrank();
    }

    function getDummyBuyOrder() private view returns(OrderEngine.Order memory) {
        return OrderEngine.Order(
            123, // Replace with the desired nonce value
            block.timestamp + 3600, // Replace with the desired validTill timestamp
            4800000000000000, // 0.0048 weth
            10000000, // 10 USDC
            0, // No fee
            maker, // Maker's Ethereum address
            operator, // Taker's Ethereum address (or null for public order)
            0xFC9a3ebc5282613E9A4544A4D7FC0e02DD6f1A43, // Recipient's Ethereum address
            weth, // MATIC token address
            usdc, // USDC token address
            true, // Replace with true or false depending on whether the order is partially fillable
            "0x", // Replace with any extra data as a hexadecimal string
            "", // Replace with predicate calldata as a hexadecimal string
            "0x", // Replace with pre-interaction data as a hexadecimal string
            "0x" // Replace with post-interaction data as a hexadecimal string
        );
    }

    function getDummySellOrder() private view returns(OrderEngine.Order memory) {
        return OrderEngine.Order(
            124, // Replace with the desired nonce value
            block.timestamp + 3600, // Replace with the desired validTill timestamp
            10000000, // 10 USDC
            4800000000000000, // 0.0048 weth
            0, // No fee
            maker, // Maker's Ethereum address
            operator, // Taker's Ethereum address (or null for public order)
            0xFC9a3ebc5282613E9A4544A4D7FC0e02DD6f1A43, // Recipient's Ethereum address
            usdc, // USDC token address
            weth, // MATIC token address
            true, // Replace with true or false depending on whether the order is partially fillable
            "0x", // Replace with any extra data as a hexadecimal string
            "", // Replace with predicate calldata as a hexadecimal string
            "0x", // Replace with pre-interaction data as a hexadecimal string
            "0x" // Replace with post-interaction data as a hexadecimal string
        );
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(advancedOrderEngine.DOMAIN_SEPARATOR(), structHash);
    }

}

/** Predicates selectors
 * and = 0x616e6400
 * or = 0x6f720000
 */