const { ethers } = require("hardhat");

/**
 * @notice Deposits native ether into `WETH` contract. It then swaps `WETH` for `stETH` using `Uniswap` as DEX
 */
async function getStakedEther(user, WETHAddr, poolAddr) {
  const WETH = await ethers.getContractAt("IWETH", WETHAddr);
  const pool = await ethers.getContractAt("IUniswapPool", poolAddr);

  /**
   * @notice 10 ETH is an arbitrary number
   */
  console.log(
    `'WETH' balance before deposit: ${parseInt(
      await WETH.balanceOf(user.address)
    )}`
  );
  await WETH.deposit({
    value: ethers.parseEther("10"),
  });
  console.log(
    `'WETH' balance after deposit: ${parseInt(
      await WETH.balanceOf(user.address)
    )}`
  );

  const amount = await WETH.balanceOf(user.address);

  await WETH.transfer(pool.target, amount);
  await pool.swap(ethers.parseEther("9"), 0, user.address, "0x");
}

module.exports = { getStakedEther };
