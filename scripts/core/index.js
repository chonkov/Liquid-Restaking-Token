const { ethers } = require("hardhat");

const {
  WETHAddr,
  poolAddr,
  strategyManagerAddr,
  delegationManagerAddr,
  operatorAddr,
  strategyAddr,
  stETHAddr,
  safeProxyFactoryAddr,
  safeImplementationAddr,
} = require("../utils/constants.js");

const { deploySafe } = require("./deploySafe");
const { delegateTo } = require("./delegateTo");
const { queueWithdrawal } = require("./queueWithdrawal");
const { completeQueuedWithdrawal } = require("./completeQueuedWithdrawal");
const { getStakedEther } = require("../mock/getStakedEther");
const { depositStETH } = require("../mock/depositStETH");
const {
  deployLiquidityRestakingManager,
} = require("../mock/deployLiquidityRestakingManager");

/**
 * @notice Main entry point
 */
async function main() {
  const [user, ...signers] = await ethers.getSigners();

  /**
   * @notice 1. Deposit native ETH into `WETH` contract -> Swap `WETH` for `stETH`
   */
  await getStakedEther(user, WETHAddr, poolAddr);

  /**
   * @notice 2. Deploy a new 'Safe' with the first 3 default account provided by Hardhat
   */
  const SafeProxy = await deploySafe(
    signers,
    safeProxyFactoryAddr,
    safeImplementationAddr
  );

  const safeProxyAddr = SafeProxy.target;

  /**
   * @notice 3. Deploy a `LiquidRestakingManager`. Users can deposit `stETH` and earn rewards
   */
  const LiquidRestakingManager = await deployLiquidityRestakingManager(
    safeProxyAddr,
    stETHAddr,
    strategyAddr,
    strategyManagerAddr,
    delegationManagerAddr
  );

  /**
   * @notice 4. User deposits `stETH` into `LiquidRestakingManager`
   */
  await depositStETH(user, LiquidRestakingManager.target, stETHAddr);

  /**
   * @notice 5. Execute a tx via `Safe`
   */
  const Helper = await (await ethers.getContractFactory("Helper")).deploy();

  await delegateTo(
    signers,
    Helper,
    SafeProxy,
    LiquidRestakingManager,
    delegationManagerAddr,
    operatorAddr
  );

  /**
   * @notice 6. Queue a withdrawal via `Safe`
   */
  const Withdrawal = await queueWithdrawal(
    signers,
    Helper,
    SafeProxy,
    LiquidRestakingManager,
    strategyAddr,
    strategyManagerAddr,
    delegationManagerAddr,
    operatorAddr
  );

  /**
   * @notice 7. Complete a queued withdrawal via `Safe`
   */
  await completeQueuedWithdrawal(
    signers,
    Withdrawal,
    LiquidRestakingManager,
    SafeProxy,
    Helper,
    stETHAddr,
    strategyManagerAddr,
    delegationManagerAddr,
    strategyAddr
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
