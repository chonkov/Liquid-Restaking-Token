const { ethers } = require("hardhat");

/**
 * @notice Simulates `user` deposit inside the `Liquid Restaking Manager`
 */
async function depositStETH(user, LiquidRestakingManagerAddr, stETHAddr) {
  const LiquidRestakingManager = await ethers.getContractAt(
    "LiquidRestakingManager",
    LiquidRestakingManagerAddr
  );
  const stETH = await ethers.getContractAt("IERC20", stETHAddr);

  const amount = await stETH.balanceOf(user.address);
  await stETH.approve(LiquidRestakingManager.target, amount);

  await LiquidRestakingManager.deposit(amount, user.address);
}

module.exports = { depositStETH };
