const { ethers } = require("hardhat");

async function delegateTo(LiquidRestakingManager, operatorAddr) {
  await LiquidRestakingManager.delegateTo(
    operatorAddr,
    ["0x", 3000000000],
    ethers.encodeBytes32String("")
  );
}

module.exports = { delegateTo };
