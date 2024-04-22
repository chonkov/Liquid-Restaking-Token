const { ethers } = require("hardhat");

const {
  WETHAddr,
  poolAddr,
  strategyManagerAddr,
  delegationManagerAddr,
  operatorAddr,
  strategyAddr,
  stETHAddr,
} = require("../utils/constants.js");

const { getStakedEther } = require("./getStakedEther");
const { depositStETH } = require("./depositStETH");
const {
  deployLiquidityRestakingManager,
} = require("./deployLiquidityRestakingManager");
const { delegateTo } = require("./delegateTo");
const { queueWithdrawal } = require("./queueWithdrawal");

async function main() {
  const [user] = await ethers.getSigners();

  await getStakedEther(user, WETHAddr, poolAddr);

  const LiquidRestakingManager = await deployLiquidityRestakingManager(
    user.address,
    stETHAddr,
    strategyAddr,
    strategyManagerAddr,
    delegationManagerAddr
  );

  await depositStETH(user, LiquidRestakingManager.target, stETHAddr);

  await delegateTo(LiquidRestakingManager, operatorAddr);

  await queueWithdrawal(user, LiquidRestakingManager, strategyAddr);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
