# RapidTransactionTrap

The **RapidTransactionTrap** is a smart contract designed for **Drosera Network** that detects suspicious wallet activity based on rapid consecutive balance changes within a short period of time.  
Its primary goal is to identify potential exploit patterns, high-frequency bot activity, or theft scenarios where assets are moved quickly.

---

## How It Works

- **WATCH** – The monitored wallet address.
- **TIME_WINDOW** – The maximum time interval (in seconds) to observe transactions (default: 30 seconds).
- **THRESHOLD** – The minimum number of balance changes within the time window that will trigger a response (default: 3).

### Detection Logic

1. The trap collects data on the **WATCH** wallet, including:
   - Wallet address
   - Current balance
   - Current timestamp

2. It compares the collected data with recent snapshots.

3. If **THRESHOLD** or more balance changes occur within the **TIME_WINDOW**, the trap triggers a response with encoded details:
   - Detection type
   - Target wallet
   - Timestamp
   - Configured time window
   - Threshold
   - Number of detected changes

---

## Example Use Cases

### 1. **Hot Wallet Compromise Detection**
Detects when a hot wallet experiences multiple rapid transfers in quick succession — a common indicator of private key theft or compromised infrastructure.

### 2. **Flash Exploit Monitoring**
Catches wallet balance changes happening too quickly for normal human activity, which could indicate:
- Exploits draining funds in multiple small transactions
- Automated attack scripts

### 3. **High-Frequency Trading Bot Alerts**
Flags when a wallet performs multiple balance updates in under 30 seconds, useful for detecting front-running bots or arbitrage bots operating at suspicious speeds.

### 4. **Drain Protection for Custodial Accounts**
Helps custodial services (e.g., exchanges or DeFi platforms) detect and respond to rapid withdrawals before significant damage occurs.

### 5. **Airdrop / Token Farming Detection**
Identifies wallets attempting to game token distributions by making multiple quick in-and-out transfers to simulate higher activity.

---

## Response Payload Format

When the trap triggers, the payload is encoded as:

| Field        | Type    | Description                                    |
|--------------|---------|------------------------------------------------|
| `type`       | `uint8` | Detection type code (0 = Rapid Transaction)    |
| `wallet`     | `address` | Address of the monitored wallet               |
| `timestamp`  | `uint256` | Time of detection                             |
| `timeWindow` | `uint256` | Observation time window in seconds            |
| `threshold`  | `uint256` | Minimum number of changes to trigger detection|
| `changes`    | `uint256` | Actual number of detected changes              |

---

## Configuration Notes

- **WATCH** address is hardcoded for this version.
- **TIME_WINDOW** and **THRESHOLD** are constants in this deployment, but they can be made configurable in future versions.
- Designed for **Ethereum-compatible blockchains**.

---

## Limitations

- Detects only **balance changes**, not specific transaction details.
- Requires frequent calls to `collect()` for accurate monitoring.
- High-frequency benign activity could trigger false positives.
