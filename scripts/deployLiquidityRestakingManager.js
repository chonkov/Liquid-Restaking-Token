const { ethers } = require("hardhat");

async function deployLiquidityRestakingManager(
  stETHAddr,
  strategyAddr,
  strategyManagerAddr,
  delegationManagerAddr
) {
  const LiquidRestakingManager = await (
    await ethers.getContractFactory("LiquidRestakingManager")
  ).deploy(
    "Liquid Restaking Ether",
    "rstETH",
    stETHAddr,
    strategyAddr,
    strategyManagerAddr,
    delegationManagerAddr
  );
  console.log(LiquidRestakingManager.target);

  return LiquidRestakingManager;
}

module.exports = { deployLiquidityRestakingManager };
