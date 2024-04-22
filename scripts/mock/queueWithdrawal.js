const { ethers } = require("hardhat");

/**
 * @notice Queues a withdrawal from EigenLayer
 */
async function queueWithdrawal(user, LiquidRestakingManager, strategyAddr) {
  const liquidRestakingTokenAddr =
    await LiquidRestakingManager.liquidRestakingToken();
  const liquidRestakingToken = await ethers.getContractAt(
    "IERC20",
    liquidRestakingTokenAddr
  );

  const shares = await liquidRestakingToken.balanceOf(user.address);

  await LiquidRestakingManager.queueWithdrawals([
    [[strategyAddr], [shares], LiquidRestakingManager.target],
  ]);
}

module.exports = { queueWithdrawal };
