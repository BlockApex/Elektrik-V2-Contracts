// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/AdvancedOrderEngine.sol";
import "../src/Predicates.sol";

contract DeployScript is Script {
    function run() external {
        AdvancedOrderEngine advancedOrderEngine;
        Predicates predicates;

        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(ownerPrivateKey);

        vm.startBroadcast(ownerPrivateKey);

        predicates = new Predicates();
        advancedOrderEngine = new AdvancedOrderEngine(IPredicates(address(predicates)), owner);

        advancedOrderEngine.manageOperatorPrivilege(owner, true);

        address[] memory tokens = new address[](10);
        bool[] memory access = new bool[](10);

        tokens[0] = 0x057e8e2bC40ECff87e6F9b28750D5E7AC004Eab9; // usdt
        tokens[1] = 0x3cf2c147d43C98Fa96d267572e3FD44A4D3940d4; // usdc
        tokens[2] = 0x4B6b9B31c72836806B0B1104Cf1CdAB8A0E3BD66; // dai
        tokens[3] = 0x9Ee1Aa18F3FEB435f811d6AE2F71B7D2a4Adce0B; // wbtc
        tokens[4] = 0x124ABC63F20c6e2088078bd61e2Db100Ff30836e; // arb
        tokens[5] = 0xecf6Bdde77C77863Ae842b145f9ab296E5eAcAF9; // op
        tokens[6] = 0x8bA5b0452b0a4da211579AA2e105c3da7C0Ad36c; // matic
        tokens[7] = 0x8488c316e23504B8554e4BdE9651802CD45aea24; // uni
        tokens[8] = 0xeDc98fc6240671dF8e7eD035CE39143320c1A174; // link
        tokens[9] = 0xeEf8e3c318fb3d86489FB258847d028adC629e14; // kub

        // Whitelisting tokens
        access[0] = true;
        access[1] = true;
        access[2] = true;
        access[3] = true;
        access[4] = true;
        access[5] = true;
        access[6] = true;
        access[7] = true;
        access[8] = true;
        access[9] = true;
        
        advancedOrderEngine.updateTokenWhitelist(tokens, access);

        vm.stopBroadcast();

    }
}