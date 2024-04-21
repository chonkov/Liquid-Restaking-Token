const { ethers } = require("hardhat");

async function getStakedEther(user, WETHAddr, poolAddr) {
  const WETH = await ethers.getContractAt("IWETH", WETHAddr);
  const pool = await ethers.getContractAt("IUniswapPool", poolAddr);

  console.log(await WETH.balanceOf(user.address));
  await WETH.deposit({
    value: ethers.parseEther("10"),
  });
  console.log(await WETH.balanceOf(user.address));

  const amount = await WETH.balanceOf(user.address);

  await WETH.transfer(pool.target, amount);
  await pool.swap(ethers.parseEther("9"), 0, user.address, "0x");

  console.log(await WETH.balanceOf(user.address));
}

module.exports = { getStakedEther };
