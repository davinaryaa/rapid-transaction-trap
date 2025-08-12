// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

interface IResponse {
    function processResponse(bool triggered, bytes memory data) external;
    function getLastResponse() external view returns (bool, bytes memory, uint256);
}

contract ResponseTrap is IResponse {
    struct ResponseRecord {
        bool wasTriggered;
        bytes responseData;
        uint256 timestamp;
        address wallet;
    }
    
    mapping(address => ResponseRecord) private responses;
    address[] private triggeredWallets;
    
    event TrapTriggered(address indexed wallet, string reason, uint256 timestamp);
    event NormalActivity(address indexed wallet, uint256 timestamp);
    
    constructor() {}
    
    function processResponse(bool triggered, bytes memory data) public override {
        address wallet = tx.origin;
        
        responses[wallet] = ResponseRecord({
            wasTriggered: triggered,
            responseData: data,
            timestamp: block.timestamp,
            wallet: wallet
        });
        
        if (triggered) {
            bool alreadyExists = false;
            for (uint256 i = 0; i < triggeredWallets.length; i++) {
                if (triggeredWallets[i] == wallet) {
                    alreadyExists = true;
                    break;
                }
            }
            
            if (!alreadyExists) {
                triggeredWallets.push(wallet);
            }
            
            (, , uint256 eventTimestamp, string memory description) = 
                abi.decode(data, (string, address, uint256, string));
            
            emit TrapTriggered(wallet, description, eventTimestamp);
            
            _handleSuspiciousActivity(wallet, description);
            
        } else {
            emit NormalActivity(wallet, block.timestamp);
        }
    }
    
    function getLastResponse() external view override returns (bool, bytes memory, uint256) {
        ResponseRecord memory record = responses[msg.sender];
        return (record.wasTriggered, record.responseData, record.timestamp);
    }
    
    function _handleSuspiciousActivity(address wallet, string memory reason) private {
    }
    
    function checkAndRespond(address trapContract) external {
        ITrap trap = ITrap(trapContract);
        
        bytes memory collectedData = trap.collect();
        
        bytes[] memory dataArray = new bytes[](1);
        dataArray[0] = collectedData;
        
        (bool shouldRespond, bytes memory data) = trap.shouldRespond(dataArray);
        
        processResponse(shouldRespond, data);
    }
    
    // Helper functions for trap monitoring and management
    function getWalletTransactionCount(address /* trapContract */, address wallet) external view returns (uint256) {
        return responses[wallet].timestamp > 0 ? 1 : 0;
    }
    
    function getWalletTransactionHistory(address wallet) external view returns (uint256[] memory) {
        uint256[] memory history = new uint256[](1);
        if (responses[wallet].timestamp > 0) {
            history[0] = responses[wallet].timestamp;
        }
        return history;
    }
    
    function isWalletSuspicious(address wallet) external view returns (bool) {
        return responses[wallet].wasTriggered && 
               responses[wallet].timestamp > 0;
    }
    
    function analyzeWalletPattern(address wallet) external view returns (
        bool isRisky,
        uint256 lastActivity,
        string memory riskLevel,
        string memory recommendation
    ) {
        ResponseRecord memory record = responses[wallet];
        
        isRisky = record.wasTriggered;
        lastActivity = record.timestamp;
        
        if (isRisky) {
            riskLevel = "HIGH";
            recommendation = "Monitor closely, consider temporary restrictions";
        } else {
            riskLevel = "LOW";
            recommendation = "Normal activity, continue monitoring";
        }
        
        return (isRisky, lastActivity, riskLevel, recommendation);
    }
    
    function getSecurityReport() external view returns (
        uint256 totalWalletsMonitored,
        uint256 suspiciousWallets,
        uint256 lastTriggerTime,
        string memory overallStatus
    ) {
        totalWalletsMonitored = triggeredWallets.length;
        suspiciousWallets = 0;
        lastTriggerTime = 0;
        
        for (uint256 i = 0; i < triggeredWallets.length; i++) {
            address wallet = triggeredWallets[i];
            if (responses[wallet].wasTriggered) {
                suspiciousWallets++;
                if (responses[wallet].timestamp > lastTriggerTime) {
                    lastTriggerTime = responses[wallet].timestamp;
                }
            }
        }
        
        if (suspiciousWallets == 0) {
            overallStatus = "ALL_CLEAR";
        } else if (suspiciousWallets <= 2) {
            overallStatus = "LOW_ALERT";
        } else {
            overallStatus = "HIGH_ALERT";
        }
        
        return (totalWalletsMonitored, suspiciousWallets, lastTriggerTime, overallStatus);
    }
    
    // Response specific view functions
    function getWalletResponse(address wallet) external view returns (ResponseRecord memory) {
        return responses[wallet];
    }
    
    function getTriggeredWallets() external view returns (address[] memory) {
        return triggeredWallets;
    }
    
    function getTriggeredWalletsCount() external view returns (uint256) {
        return triggeredWallets.length;
    }
    
    function isWalletTriggered(address wallet) external view returns (bool) {
        return responses[wallet].wasTriggered && 
               responses[wallet].timestamp > 0;
    }
    
    function getResponseHistory(address wallet) external view returns (
        bool triggered,
        string memory eventType,
        address detectedWallet,
        uint256 timestamp,
        string memory description
    ) {
        ResponseRecord memory record = responses[wallet];
        
        if (record.responseData.length > 0) {
            (eventType, detectedWallet, timestamp, description) = 
                abi.decode(record.responseData, (string, address, uint256, string));
        }
        
        return (record.wasTriggered, eventType, detectedWallet, record.timestamp, description);
    }
}