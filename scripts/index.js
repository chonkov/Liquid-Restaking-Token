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
const { delegateTo } = require("./delegateTo");
const { getStakedEther } = require("./mock/getStakedEther");
const { depositStETH } = require("./mock/depositStETH");
const {
  deployLiquidityRestakingManager,
} = require("./mock/deployLiquidityRestakingManager");

require("dotenv").config();

/**
 * @notice Main entry point
 */
async function main() {
  const [user, ...signers] = await ethers.getSigners();

  const privateKey1 = process.env.PRIVATE_KEY_1 || "";
  const privateKey2 = process.env.PRIVATE_KEY_2 || "";
  const privateKey3 = process.env.PRIVATE_KEY_3 || "";

  // console.log(privateKey1);
  // console.log(privateKey2);
  // console.log(privateKey3);

  const signer1 = new ethers.Wallet(privateKey1);
  const signer2 = new ethers.Wallet(privateKey2);
  const signer3 = new ethers.Wallet(privateKey3);

  // const signers = [signer1, signer2, signer3];
  // let payload = ethers.AbiCoder.defaultAbiCoder().encode(["address", "address", "uint256" ], [ address1, address2, amountRound2 ]);
  // let payloadHash = ethers.keccak256(payload);
  // let signature = await signer.signMessage(ethers.getBytes(payloadHash));

  // console.log(signers[0].address);
  // console.log(signers[1].address);
  // console.log(signers[2].address);

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
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
