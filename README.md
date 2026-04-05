[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/hostit-events/ticket)

# HostIt Protocol - Ticket Smart Contracts

## Overview

This repository contains the smart contracts for the **Ticket** module of the [HostIt Protocol](https://www.hostit.events), a decentralized event and ticketing platform. The Ticket contracts manage the lifecycle of event tickets, including creation, sales, fee management, check-in, and administrative controls. The system is modular, upgradeable, and designed for extensibility and security.

## Architecture

The Ticket contracts are implemented using the [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535) for modular and upgradeable smart contracts. The core logic is split into several "facets," each responsible for a specific domain:

- **FactoryFacet**: Handles ticket creation, updates, and querying ticket data.
- **MarketplaceFacet**: Manages ticket sales, fee configuration, withdrawals, and marketplace logic.
- **CheckInFacet**: Supports ticket check-in and admin management for events.
- **Init**: Handles protocol initialization and configuration.

Supporting libraries and storage contracts are used to manage state and reusable logic.

## Key Contracts

- `src/facets/FactoryFacet.sol`: Ticket creation, update, and admin queries.
- `src/facets/MarketplaceFacet.sol`: Ticket minting, fee management, and withdrawals.
- `src/facets/CheckInFacet.sol`: Check-in logic and admin controls.
- `src/inits/HostItInit.sol`: Initialization logic for protocol deployment.
- `src/interfaces/IMarketplace.sol`: Interface for marketplace operations.

## Features

- **Modular architecture** for upgradeability and separation of concerns
- **Fee management**: Multi-fee support per ticket, including HostIt platform fees
- **Ticket minting**: Secure, on-chain ticket sales
- **Check-in system**: On-chain proof of attendance
- **Admin roles**: Fine-grained admin controls per ticket
- **Upgradeable**: Built on the Diamond Standard for future-proofing

## Directory Structure

```
/contract-root
├── src/
│   ├── facets/
│   │   ├── FactoryFacet.sol
│   │   ├── MarketplaceFacet.sol
│   │   └── CheckInFacet.sol
│   ├── inits/
│   │   └── HostItInit.sol
│   ├── interfaces/
│   │   └── IMarketplace.sol
│   └── libs/
│       └── ...
├── script/
│   └── ...
├── test/
│   └── ...
└── ...
```

## Getting Started

### Prerequisites
- [Foundry](https://book.getfoundry.sh/) (for Solidity development and testing)
- Node.js (for scripting, if needed)
- An Ethereum-compatible wallet and testnet access

### Installation
1. Clone this repository
2. Install dependencies:
   ```sh
   forge install
   ```

### Compilation
```sh
forge build
```

### Testing
```sh
forge test
```

### Deployment
Deployment scripts are located in the `/script` directory. Example:
```sh
forge script script/DeployHostItTickets.s.sol --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast
```

## Dimensional Units

The inline `// {unit}` comments throughout the Solidity source annotate dimensional types to prevent unit-mismatch bugs.

### Base Units

| Unit | Meaning |
|------|---------|
| `{tok}` | Token amounts (ETH or ERC20), in the smallest unit of the payment token selected via `FeeType` |
| `{s}` | Timestamps and durations in seconds (Unix epoch for timestamps, raw seconds for durations) |
| `{1}` | Dimensionless quantities (basis-point ratios, boolean flags, counters) |
| `{ticket}` | Ticket token IDs and counts (NFT minting counters, `maxTickets`, `soldTickets`) |
| `{ticketId}` | Ticket type identifiers (sequential `uint64` IDs assigned by the factory) |
| `{day}` | Day index offset from event start (used in check-in tracking, derived from seconds) |
| `{addr}` | Ethereum addresses (token, admin, buyer) |

### Derived Units

| Unit | Meaning |
|------|---------|
| `{1/1}` | Fee fraction: `HOSTIT_FEE_BPS / FEE_BASIS_POINTS` = 300 / 10,000 = 0.03 |

### Precision

- **BPS** -- Basis points (1/10,000). `FEE_BASIS_POINTS = 10_000`, `HOSTIT_FEE_BPS = 300` (3%).

## Security
- All contracts are licensed under AGPL-3.0-only.
- Uses OpenZeppelin libraries and patterns for security.
- Modular upgradeable architecture to enable rapid patching.

## Contributing
Pull requests, issues, and suggestions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) if available.

## License
[AGPL-3.0-only](LICENSE)

---

*For more information, visit [hostit.events](https://www.hostit.events) or contact the maintainers.*
