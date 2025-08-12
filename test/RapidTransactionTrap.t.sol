// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {RapidTransactionTrap} from "../src/RapidTransactionTrap.sol";

contract RapidTransactionTrapTest is Test {
    RapidTransactionTrap public trap;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    event TransactionRecorded(address indexed wallet, uint256 timestamp, uint256 count);
    
    function setUp() public {
        trap = new RapidTransactionTrap();
        vm.warp(100);
    }
    
    function test_InitialCollect() public {
        vm.prank(user1, user1);
        bytes memory data = trap.collect();
        
        (address wallet, uint256 currentTime, uint256[] memory timestamps, uint256 count) = 
            abi.decode(data, (address, uint256, uint256[], uint256));
        
        assertEq(wallet, user1);
        assertEq(timestamps.length, 0);
        assertEq(count, 0);
        assertTrue(currentTime > 0);
    }
    
    function test_UpdateTransactionRecord() public {
        vm.startPrank(user1, user1);
        
        trap.updateTransactionRecord();
        
        bytes memory data = trap.collect();
        (address wallet, , uint256[] memory timestamps, uint256 count) = 
            abi.decode(data, (address, uint256, uint256[], uint256));
        
        assertEq(wallet, user1);
        assertEq(timestamps.length, 1);
        assertEq(count, 1);
        
        vm.stopPrank();
    }
    
    function test_MultipleTransactionsWithinWindow() public {
        vm.startPrank(user1, user1);
        
        uint256 startTime = 1000;
        vm.warp(startTime);
        
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 10);
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 20);
        trap.updateTransactionRecord();
        
        bytes memory data = trap.collect();
        (address wallet, , uint256[] memory timestamps, uint256 count) = 
            abi.decode(data, (address, uint256, uint256[], uint256));
        
        assertEq(wallet, user1);
        assertEq(timestamps.length, 3);
        assertEq(count, 3);
        
        vm.stopPrank();
    }
    
    function test_ShouldRespondWithRapidTransactions() public {
        vm.startPrank(user1, user1);
        
        uint256 startTime = 1000;
        vm.warp(startTime);
        
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 5);
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 10);
        trap.updateTransactionRecord();
        
        bytes memory collectData = trap.collect();
        
        bytes[] memory dataArray = new bytes[](1);
        dataArray[0] = collectData;
        
        (bool shouldRespond, bytes memory responseData) = trap.shouldRespond(dataArray);
        
        assertTrue(shouldRespond);
        
        (string memory alertType, address wallet, uint256 timestamp, string memory message) = 
            abi.decode(responseData, (string, address, uint256, string));
        
        assertEq(alertType, "RAPID_TRANSACTION_DETECTED");
        assertEq(wallet, user1);
        assertTrue(timestamp > 0);
        assertEq(keccak256(abi.encodePacked(message)), keccak256(abi.encodePacked("Multiple transactions detected within 30 seconds")));
        
        vm.stopPrank();
    }
    
    function test_ShouldNotRespondWithNormalTransactions() public {
        vm.startPrank(user1, user1);
        
        uint256 startTime = 1000;
        vm.warp(startTime);
        
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 5);
        trap.updateTransactionRecord();
        
        bytes memory collectData = trap.collect();
        
        bytes[] memory dataArray = new bytes[](1);
        dataArray[0] = collectData;
        
        (bool shouldRespond, bytes memory responseData) = trap.shouldRespond(dataArray);
        
        assertFalse(shouldRespond);
        
        (string memory alertType, address wallet, , string memory message) = 
            abi.decode(responseData, (string, address, uint256, string));
        
        assertEq(alertType, "NORMAL_TRANSACTION");
        assertEq(wallet, user1);
        assertEq(keccak256(abi.encodePacked(message)), keccak256(abi.encodePacked("Transaction pattern normal")));
        
        vm.stopPrank();
    }
    
    function test_TransactionWindowCleanup() public {
        vm.startPrank(user1, user1);
        
        uint256 startTime = 1000;
        vm.warp(startTime);
        
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 5);
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 40);
        
        trap.updateTransactionRecord();
        
        bytes memory data = trap.collect();
        (, , uint256[] memory timestamps, uint256 count) = 
            abi.decode(data, (address, uint256, uint256[], uint256));
        
        assertEq(timestamps.length, 1);
        assertEq(count, 1);
        
        vm.stopPrank();
    }
    
    function test_MultipleUsersIndependentRecords() public {
        uint256 startTime = 1000;
        vm.warp(startTime);
        
        vm.startPrank(user1, user1);
        trap.updateTransactionRecord();
        vm.warp(startTime + 5);
        trap.updateTransactionRecord();
        vm.warp(startTime + 10);
        trap.updateTransactionRecord();
        vm.stopPrank();
        
        vm.startPrank(user2, user2);
        vm.warp(startTime + 15);
        trap.updateTransactionRecord();
        vm.stopPrank();
        
        vm.prank(user1, user1);
        bytes memory data1 = trap.collect();
        (, , uint256[] memory timestamps1, uint256 count1) = 
            abi.decode(data1, (address, uint256, uint256[], uint256));
        
        vm.prank(user2, user2);
        bytes memory data2 = trap.collect();
        (, , uint256[] memory timestamps2, uint256 count2) = 
            abi.decode(data2, (address, uint256, uint256[], uint256));
        
        assertEq(count1, 3);
        assertEq(timestamps1.length, 3);
        
        assertEq(count2, 1);
        assertEq(timestamps2.length, 1);
    }
    
    function test_ShouldRespondWithNoData() public view {
        bytes[] memory emptyDataArray = new bytes[](0);
        
        (bool shouldRespond, bytes memory responseData) = trap.shouldRespond(emptyDataArray);
        
        assertFalse(shouldRespond);
        
        (string memory alertType, address wallet, uint256 timestamp, string memory message) = 
            abi.decode(responseData, (string, address, uint256, string));
        
        assertEq(alertType, "NO_DATA");
        assertEq(wallet, address(0));
        assertEq(timestamp, 0);
        assertEq(keccak256(abi.encodePacked(message)), keccak256(abi.encodePacked("No transaction data provided for analysis")));
    }
    
    function test_EdgeCaseExactThreshold() public {
        vm.startPrank(user1, user1);
        
        uint256 startTime = 1000;
        vm.warp(startTime);
        
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 10);
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 20);
        trap.updateTransactionRecord();
        
        bytes memory collectData = trap.collect();
        
        bytes[] memory dataArray = new bytes[](1);
        dataArray[0] = collectData;
        
        (bool shouldRespond, ) = trap.shouldRespond(dataArray);
        
        assertTrue(shouldRespond);
        
        vm.stopPrank();
    }
    
    function test_EdgeCaseTimeWindowBoundary() public {
        vm.startPrank(user1, user1);
        
        uint256 startTime = 1000;
        vm.warp(startTime);
        
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 15);
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 25);
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 26);
        bytes memory collectData = trap.collect();
        
        bytes[] memory dataArray = new bytes[](1);
        dataArray[0] = collectData;
        
        (bool shouldRespond, ) = trap.shouldRespond(dataArray);
        
        assertTrue(shouldRespond);
        
        vm.stopPrank();
    }
    
    function test_EdgeCaseOutsideWindow() public {
        vm.startPrank(user1, user1);
        
        uint256 startTime = 1000;
        vm.warp(startTime);
        
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 35);
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 40);
        trap.updateTransactionRecord();
        
        bytes memory collectData = trap.collect();
        
        bytes[] memory dataArray = new bytes[](1);
        dataArray[0] = collectData;
        
        (bool shouldRespond, ) = trap.shouldRespond(dataArray);
        
        assertFalse(shouldRespond);
        
        vm.stopPrank();
    }
    
    function test_FuzzRapidTransactionDetection(uint8 numTransactions, uint8 timeSpread) public {
        numTransactions = uint8(bound(numTransactions, 1, 10));
        timeSpread = uint8(bound(timeSpread, 1, 60));
        
        vm.startPrank(user1, user1);
        
        uint256 startTime = 1000;
        vm.warp(startTime);
        
        for (uint256 i = 0; i < numTransactions; i++) {
            if (i > 0) {
                uint256 timeIncrement = (uint256(timeSpread) * i) / numTransactions;
                vm.warp(startTime + timeIncrement);
            }
            trap.updateTransactionRecord();
        }
        
        bytes memory collectData = trap.collect();
        
        bytes[] memory dataArray = new bytes[](1);
        dataArray[0] = collectData;
        
        (bool shouldRespond, ) = trap.shouldRespond(dataArray);
        
        bool expectedResponse = (numTransactions >= 3 && timeSpread <= 30);
        
        if (expectedResponse) {
            assertTrue(shouldRespond);
        }
        
        vm.stopPrank();
    }
    
    function test_LargeTimeGap() public {
        vm.startPrank(user1, user1);
        
        uint256 startTime = 1000;
        vm.warp(startTime);
        
        trap.updateTransactionRecord();
        
        vm.warp(startTime + 1000);
        trap.updateTransactionRecord();
        
        bytes memory data = trap.collect();
        (, , uint256[] memory timestamps, uint256 count) = 
            abi.decode(data, (address, uint256, uint256[], uint256));
        
        assertEq(timestamps.length, 1);
        assertEq(count, 1);
        
        vm.stopPrank();
    }
}