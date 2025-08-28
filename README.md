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
