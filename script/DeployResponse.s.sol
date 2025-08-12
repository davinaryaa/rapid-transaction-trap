// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ResponseTrap.sol";

contract DeployResponse is Script {
    function run() external {
        vm.startBroadcast();
        ResponseTrap response = new ResponseTrap();
        console.log("ResponseTrap deployed at:", address(response));
        vm.stopBroadcast();
    }
}