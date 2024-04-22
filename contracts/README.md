# Liquid Restaking Manager Contracts

## Table of Contents

- [Description](#description)

## Description

There are two main contracts - the `Liquid Restaking Token` (LRT) and `Liquid Restaking Manager` (LRM). The token represents the owned 'shares' by a particular users, thorough which he/she can earn additional yield. The `LRM` is the the manager of the system that lives on-chain. Users deposit LSTs into it (e.g. stETH) and receive `rstETH` in return. The 'admin' of the contract, a `Safe` multi-signature wallet, has the authorization to perform actions such as: delegation to/ undelegation from an operator, queue & complete withdrawals. The contract also heavily relies on the implementation of Synthetix's 'Staking Rewards' contract for tracking stakes by users and allowing them to claim their appropriate rewards.
