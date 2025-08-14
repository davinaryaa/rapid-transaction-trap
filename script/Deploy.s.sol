// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RapidTransactionTrap.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        RapidTransactionTrap trap = new RapidTransactionTrap();
        console.log("Trap deployed at:", address(trap));
        vm.stopBroadcast();
    }
}