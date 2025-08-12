// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

contract RapidTransactionTrap is ITrap {
    struct TransactionRecord {
        uint256[] timestamps;
        uint256 count;
    }
    
    mapping(address => TransactionRecord) private walletTransactions;
    uint256 private constant TIME_WINDOW = 30;
    uint256 private constant THRESHOLD = 3;
    
    constructor() {}
    
    function collect() external view override returns (bytes memory) {
        address wallet = tx.origin;
        uint256 currentTime = block.timestamp;
        
        TransactionRecord storage record = walletTransactions[wallet];
        
        bytes memory transactionData = abi.encode(
            wallet,
            currentTime,
            record.timestamps,
            record.count
        );
        
        return transactionData;
    }
    
    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length > 0) {
            (address dataWallet, uint256 dataTime, uint256[] memory timestamps, uint256 count) = 
                abi.decode(data[0], (address, uint256, uint256[], uint256));
            
            bool isRapidTransaction = false;
            
            if (count >= THRESHOLD) {
                uint256 validTransactions = 0;
                uint256 windowStart = dataTime - TIME_WINDOW;
                
                for (uint256 i = 0; i < timestamps.length; i++) {
                    if (timestamps[i] >= windowStart) {
                        validTransactions++;
                    }
                }
                
                isRapidTransaction = validTransactions >= THRESHOLD;
            }
            
            bytes memory responseData;
            if (isRapidTransaction) {
                responseData = abi.encode(
                    "RAPID_TRANSACTION_DETECTED",
                    dataWallet,
                    dataTime,
                    "Multiple transactions detected within 30 seconds"
                );
            } else {
                responseData = abi.encode(
                    "NORMAL_TRANSACTION",
                    dataWallet,
                    dataTime,
                    "Transaction pattern normal"
                );
            }
            
            return (isRapidTransaction, responseData);
        }
        
        bytes memory fallbackData = abi.encode(
            "NO_DATA",
            address(0),
            uint256(0),
            "No transaction data provided for analysis"
        );
        
        return (false, fallbackData);
    }
    
    // Helper function to manually update transaction records
    function updateTransactionRecord() external {
        address wallet = tx.origin;
        uint256 currentTime = block.timestamp;
        
        TransactionRecord storage record = walletTransactions[wallet];
        
        record.timestamps.push(currentTime);
        record.count++;
        
        uint256 windowStart = currentTime - TIME_WINDOW;
        
        uint256[] memory newTimestamps = new uint256[](record.timestamps.length);
        uint256 newCount = 0;
        
        for (uint256 i = 0; i < record.timestamps.length; i++) {
            if (record.timestamps[i] >= windowStart) {
                newTimestamps[newCount] = record.timestamps[i];
                newCount++;
            }
        }
        
        delete record.timestamps;
        for (uint256 i = 0; i < newCount; i++) {
            record.timestamps.push(newTimestamps[i]);
        }
        record.count = newCount;
    }
}