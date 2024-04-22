const { ethers } = require("hardhat");

/**
 * @notice Deploys `Liquid Restaking Manager` with all the required constructor arguments
 */
async function deployLiquidityRestakingManager(
  admin,
  stETHAddr,
  strategyAddr,
  strategyManagerAddr,
  delegationManagerAddr
) {
  const LiquidRestakingManager = await (
    await ethers.getContractFactory("LiquidRestakingManager")
  ).deploy(
    admin,
    "Liquid Restaking Ether",
    "rstETH",
    "Governance Liquid Restaking Token",
    "GLRT",
    stETHAddr,
    strategyAddr,
    strategyManagerAddr,
    delegationManagerAddr
  );
  console.log(
    `LiquidRestakingManager address: ${LiquidRestakingManager.target}`
  );

  return LiquidRestakingManager;
}

module.exports = { deployLiquidityRestakingManager };
