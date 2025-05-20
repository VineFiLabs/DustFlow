# DustFlow

[![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)]

A decentralized pre-market trading platform based on the RWA stablecoin DUST.

## Features
- **Pre-market Trading**: Trade tokens of upcoming projects before they go live. 
- **Mint DUST**: Create DUST stablecoins backed by Real World Asset (RWA) stablecoins.
- **Versatile Payments**:
  - Standard transfers.
  - Secure transfers using the Flow protocol with DUST.
  - Flow-based payments with DUST.

## How It Works
1. **Order Placement**: Buyers and sellers place orders with specified price and amount in DUST.
2. **Collateral Handling**: Sellers pledge token collateral; buyers lock DUST collateral against orders.
3. **Execution & Settlement**: Orders match off-chain; collateral and tokens settle on-chain at market close.
4. **Pledge & Refund**: Unmatched orders can be canceled before settlement time, subject to cancellation fees.

## Fee Structure
| Volume (in units)                            | Fee      |
|----------------------------------------------|----------|
| 10 ≤ x < 1,000                               | 1%       |
| 1,000 ≤ x < 10,000                           | 0.8%     |
| x ≥ 10,000                                   | 0.5%     |
| **Order Cancellation** (if market open)      | 0.5%     |

## Architecture
- [DustFlow Architecture] <https://DustFlow-docs.vercel.app/docs/architecture>
- **Smart Contracts**: Core on-chain logic for order management and settlement.
- **Off-Chain Modules**: Matching engine, auction algorithms, and monitoring services.
- **RWA Integration**: External services to mint and redeem DUST against real-world assets.

## Future
1. Improve the functions of the RWA stablecoin DUST, introduce lending into DUST, and use DUST as the mainstream yield aggregator for RWA stablecoins;  
2. List DustFlow Payment on the apple store and open the SDK access and documentation;  
3. Explore the application of Pre-Market in futures trading, for example: trading the futures of ETH for 2026.1.1.  

## Getting Started
### Prerequisites
- Node.js v16+ and npm or Yarn
- Hardhat (v2.0+)

### Installation
```bash
# Clone the repository
git clone https://github.com/quqicolour/DustFlow.git
cd DustFlow

# Install dependencies
npm install  # or yarn
```

### Configuration
Create a `.env` file with the following variables:
```
RPC_URL=<Your Ethereum RPC URL>
PRIVATE_KEY1=<Your deployer account private key>
```

## Usage
```bash


# Deploy contracts via Ignition
npx hardhat run scripts/deploy.js --network pharos
```

## Contributing
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/MyFeature`).
3. Commit your changes (`git commit -m 'Add MyFeature'`).
4. Push to the branch (`git push origin feature/MyFeature`).
5. Open a pull request.

## License
This project is licensed under the AGPL-3.0 License. See the [LICENSE](LICENSE) file for details.