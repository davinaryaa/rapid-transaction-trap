// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RapidTxnLogger {
    event RapidActivity(
        uint8 indexed reason,
        address indexed wallet,
        uint256 observedAt,
        uint256 windowSec,
        uint256 threshold,
        uint256 changes
    );

    function processResponse(bytes calldata payload) external {
        (uint8 reason, address w, uint256 ts, uint256 windowSec, uint256 threshold, uint256 changes) =
            abi.decode(payload, (uint8, address, uint256, uint256, uint256, uint256));
        emit RapidActivity(reason, w, ts, windowSec, threshold, changes);
    }
}