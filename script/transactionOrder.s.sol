// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/AdvancedOrderEngine.sol";
import "../src/Predicates.sol";

contract TransactionScript is Script {
    Predicates predicates = Predicates(0xF290FF9ED61cB43F96D3F374474f05810d505430);
    AdvancedOrderEngine advancedOrderEngine = AdvancedOrderEngine(0xDaC771732B2211e2d2c691DC95f9Cf75A61a5974);
    uint256 ownerPrivateKey = vm.envUint("LIVE_MAKER1");
    address owner = vm.addr(ownerPrivateKey);
    uint256 maker1PrivateKey = vm.envUint("LIVE_MAKER1");
    address maker1 = vm.addr(maker1PrivateKey);
    uint256 maker2PrivateKey = vm.envUint("LIVE_MAKER2");
    address maker2 = vm.addr(maker2PrivateKey);
    IERC20 usdc = IERC20(0x3cf2c147d43C98Fa96d267572e3FD44A4D3940d4); 
    IERC20 wmatic = IERC20(0x8bA5b0452b0a4da211579AA2e105c3da7C0Ad36c); 
    
    function run() external {

        // vm.startBroadcast(maker1PrivateKey);

        // usdc.approve(address(advancedOrderEngine), UINT256_MAX);

        // vm.stopBroadcast();

        // vm.startBroadcast(maker2PrivateKey);

        // wmatic.approve(address(advancedOrderEngine), UINT256_MAX);

        // vm.stopBroadcast();

        vm.startBroadcast(ownerPrivateKey);

        OrderEngine.Order memory buyOrder = getDummyBuyOrder();
        OrderEngine.Order memory sellOrder = getDummySellOrder();
        OrderEngine.Order[] memory orders = new OrderEngine.Order[](2);

        orders[0] = sellOrder;
        orders[1] = buyOrder;

        uint256[] memory sell = new uint256[](2);

        sell[0] = sellOrder.sellTokenAmount * 1e18;
        sell[1] = buyOrder.sellTokenAmount * 1e18;

        uint256[] memory buy = new uint256[](2);

        buy[0] = sellOrder.buyTokenAmount * 1e18;
        buy[1] = buyOrder.buyTokenAmount * 1e18;

        bytes[] memory sigs = new bytes[](2);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(maker2PrivateKey, _hashTypedDataV4(OrderEngine.hash(sellOrder)));
        bytes memory sellOrderSignature = abi.encodePacked(r, s, v);

        console2.logBytes32(_hashTypedDataV4(OrderEngine.hash(sellOrder)));

        (v, r, s) = vm.sign(maker1PrivateKey, _hashTypedDataV4(OrderEngine.hash(buyOrder)));
        bytes memory buyOrderSignature = abi.encodePacked(r, s, v);
        console2.logBytes32(_hashTypedDataV4(OrderEngine.hash(buyOrder)));

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

        vm.stopBroadcast();

    }

    function getDummyBuyOrder() private view returns(OrderEngine.Order memory) {
        return OrderEngine.Order(
            1,
            1700948778,
            10000000,
            4800000000000000,
            0,
            maker1,
            owner,
            maker1,
            address(usdc),
            address(wmatic),
            true,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            "",
            '0x',
            '0x'
        );
    }

    function getDummySellOrder() private view returns(OrderEngine.Order memory) {
        return OrderEngine.Order(
            2,
            1700948778,
            4800000000000000,
            10000000,
            0,
            maker2,
            owner,
            maker2,
            address(wmatic),
            address(usdc),
            true,
            0x0000000000000000000000000000000000000000000000000000000000000000,
            '',
            '0x',
            '0x'
        );
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(advancedOrderEngine.DOMAIN_SEPARATOR(), structHash);
    }
}