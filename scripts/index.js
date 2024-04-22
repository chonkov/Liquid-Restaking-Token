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
} = require("./utils/constants.js");

const { deploySafe } = require("./deploySafe");
const { getStakedEther } = require("./mock/getStakedEther");
const { depositStETH } = require("./mock/depositStETH");
const {
  deployLiquidityRestakingManager,
} = require("./mock/deployLiquidityRestakingManager");

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
   * @notice Last part is still NOT finished
   * @notice 5. Execute a tx via `Safe`
   */
  const currentNonce = await SafeProxy.nonce();

  const to = LiquidRestakingManager.target;
  const Helper = await (await ethers.getContractFactory("Helper")).deploy();

  const txHash = await Helper.getTransactionHash(
    to,
    operatorAddr,
    currentNonce
  );
  // console.log(txHash);

  const signatures = [];
  for (let i = 1; i <= 2; i++) {
    const signature = await signers[i].signMessage(txHash);
    signatures.push(signature);
  }

  // console.log(signatures);

  const executeTxData = await Helper.executeTx(
    to,
    operatorAddr,
    signatures[0],
    signatures[1]
  );
  // console.log(executeTxData);

  const DelegationManager = await ethers.getContractAt(
    "IDelegationManager",
    delegationManagerAddr
  );

  console.log(
    `'LiquidRestakingManager' delegated: ${await DelegationManager.isDelegated(
      to
    )}`
  );

  // await signers[0].sendTransaction({
  //   to: safeProxyAddr,
  //   data: executeTxData,
  // });

  // console.log(await DelegationManager.isDelegated(to));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
