const { ethers } = require("hardhat");

async function deployLiquidityRestakingManager(
  user,
  stETHAddr,
  strategyAddr,
  strategyManagerAddr,
  delegationManagerAddr
) {
  const LiquidRestakingManager = await (
    await ethers.getContractFactory("LiquidRestakingManager")
  ).deploy(
    user.address,
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
