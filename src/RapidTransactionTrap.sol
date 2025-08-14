// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "drosera-contracts/interfaces/ITrap.sol";

contract RapidTransactionTrap is ITrap {
    address public constant WATCH = 0x1234567890aBCDef1234567890AbcDEF12345678;

    uint256 public constant TIME_WINDOW = 30;
    uint256 public constant THRESHOLD = 3;

    function collect() external view returns (bytes memory) {
        return abi.encode(WATCH, WATCH.balance, block.timestamp);
    }

    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory) {
        if (data.length < 2) return (false, "");

        (address w0, uint256 bal0, uint256 ts0) = abi.decode(
            data[0], (address, uint256, uint256)
        );

        uint256 changes = 0;
        uint256 lastBal = bal0;

        for (uint256 i = 1; i < data.length; i++) {
            (address wi, uint256 bali, uint256 tsi) = abi.decode(
                data[i], (address, uint256, uint256)
            );

            if (wi != w0) break;

            if (ts0 - tsi > TIME_WINDOW) break;

            if (bali != lastBal) {
                changes++;
                lastBal = bali;
                if (changes >= THRESHOLD) {
                    bytes memory payload = abi.encode(
                        uint8(0), w0, ts0, TIME_WINDOW, THRESHOLD, changes
                    );
                    return (true, payload);
                }
            }
        }

        return (false, "");
    }
}