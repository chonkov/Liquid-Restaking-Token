const { ethers } = require("hardhat");

async function depositStETH(user, LiquidRestakingManagerAddr, stETHAddr) {
  const LiquidRestakingManager = await ethers.getContractAt(
    "LiquidRestakingManager",
    LiquidRestakingManagerAddr
  );
  const stETH = await ethers.getContractAt("IERC20", stETHAddr);

  const amount = await stETH.balanceOf(user.address);
  console.log(amount);
  await stETH.approve(LiquidRestakingManager.target, amount);
  console.log(
    await stETH.allowance(user.address, LiquidRestakingManager.target)
  );

  await LiquidRestakingManager.deposit(amount, user.address);
}

module.exports = { depositStETH };
