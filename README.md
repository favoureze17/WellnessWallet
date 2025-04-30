# WellnessWallet

A blockchain-powered financial ecosystem built on Stacks to support mental wellness programs and individuals seeking therapeutic services.

## Overview

WellnessWallet is a smart contract vault system designed to collect, manage, and distribute cryptocurrency funds for mental wellness initiatives. The platform creates a transparent and accountable mechanism for directing financial resources to those in need of mental health support while protecting participant privacy.

## Features

- **Secure Pledge Collection**: Accept STX pledges with configurable minimum thresholds
- **Participant Management**: Register and track program participants receiving wellness support
- **Transparent Fund Allocation**: Auditable distribution of funds to approved participants
- **Guardian Controls**: Comprehensive administrative tools for vault management
- **Safety Protocols**: Built-in protection mechanisms including emergency mode
- **Guardianship Transfer**: Seamless transition of administrative responsibilities

## Smart Contract Functions

### Public Functions

- `make-pledge`: Submit financial support to the wellness vault
- `register-new-participant`: Enroll a new wellness program participant
- `allocate-funds`: Distribute funds to registered participants
- `set-minimum-pledge`: Adjust the minimum pledge requirement
- `toggle-vault-status`: Enable or disable the vault operations
- `enable-emergency-mode`: Activate emergency safeguards
- `disable-emergency-mode`: Return vault to normal operations
- `update-participant-status`: Modify a participant's program status
- `transfer-guardian-rights`: Transition administrative control to a new guardian

### Read-Only Functions

- `get-vault-guardian`: View the current vault administrator
- `get-vault-balance`: Check total available wellness funds
- `get-participant-information`: View data about registered participants
- `get-supporter-information`: Access pledge history for supporters
- `check-vault-operational-status`: Verify current vault operational state

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing
- [Stacks Wallet](https://www.hiro.so/wallet) for blockchain interactions

### Installation

1. Clone this repository
```bash
git clone https://github.com/favoureze17/wellnesswallet.git
cd wellnesswallet
```

2. Set up the development environment
```bash
clarinet integrate
```

3. Run tests
```bash
clarinet test
```

### Deployment

1. Build the contract
```bash
clarinet build
```

2. Deploy to the Stacks blockchain
```bash
# Using stacks-cli (example)
stacks deploy --network=testnet --keychain=/path/to/keychain.json --fee=1000 ./contracts/wellnesswallet.clar
```

## Usage Examples

### Making a Pledge
```clarity
;; Make a pledge of 10 STX
(contract-call? .wellnesswallet make-pledge)
```

### Registering a New Participant
```clarity
;; Register a new wellness program participant
(contract-call? .wellnesswallet register-new-participant 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Allocating Funds
```clarity
;; Allocate 5 STX to a participant
(contract-call? .wellnesswallet allocate-funds 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u5000000)
```

## Security Considerations

- Multi-layered permission systems prevent unauthorized access
- Vault guardian role controls all administrative functions
- Emergency protocols can freeze operations if suspicious activity is detected
- Balance verification prevents unauthorized fund transfers
- Input validation ensures transactional integrity

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Mental wellness advocacy organizations for inspiration
- Stacks blockchain community for technical support
- All developers and contributors to this open-source initiative