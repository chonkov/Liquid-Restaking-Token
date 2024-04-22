const { ethers } = require("hardhat");

/**
 * @notice Delegates to the operator. The signature and salt are not required. Timestamp is hard-coded to 3 billion - current timestamp is less than 2
 */
async function delegateTo(LiquidRestakingManager, operatorAddr) {
  await LiquidRestakingManager.delegateTo(
    operatorAddr,
    ["0x", 2000000000],
    ethers.encodeBytes32String("")
  );
}

module.exports = { delegateTo };
