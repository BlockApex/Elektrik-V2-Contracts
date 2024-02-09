// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Mocks/FacilitatorSwap.sol";

contract DeployScript is Script {
    function run() external {
        FacilitatorSwap facilitatorSwap;

        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY");
        // address owner = vm.addr(ownerPrivateKey);

        vm.startBroadcast(ownerPrivateKey);

        facilitatorSwap = new FacilitatorSwap();

        vm.stopBroadcast();

    }
}