# Liquid Restaking Manager Scripts

## Table of Contents

- [Description](#description)

## Description

1. `Utils` folder consists of all the addresses deployed on mainnet.

2. Inside `Mock` folder, there are scripts, which 'mock' the flow of the system. The owner is a single entity and the `Liquid Restaking Manager` interacts with the `Delegation` and `Strategy` managers deployed on mainnet via 'forking'. Deploy script:

```
npx hardhat node --fork <YOUR_RPC_URL>
```

```
npx hardhat run scripts/mock/deploySystem.js --network localhost
```

3. Inside `Core` dir are the main scripts. `Index.js` is the entry point for the script interaction. Similarly to the 'mocks', it relies on forking mainnet. The difference is that `admin` of the `Liquid Restaking Manager` is a `Safe` wallet, owned by the first three default accounts provided by Hardhat. Through the multi-sig, admins have access to certain functionalities inside the `Liquid Restaking Manager` contract such as: delegating to/undelegating from a registered operator, queuing & completing withdrawals. Deploy script:

```
npx hardhat node --fork <YOUR_RPC_URL>
```

```
npx hardhat run scripts/core/index.js --network localhost
```
