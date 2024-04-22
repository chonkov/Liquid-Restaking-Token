const { ethers } = require("hardhat");
const { EthersAdapter, SafeFactory } = require("@safe-global/protocol-kit");
require("dotenv").config();

const {
  WETHAddr,
  poolAddr,
  strategyManagerAddr,
  delegationManagerAddr,
  operatorAddr,
  strategyAddr,
  stETHAddr,
  safeProxyFactoryAddr,
  safeImplementationAddr,
} = require("./constants.js");

async function main() {
  const [user, user2, user3] = await ethers.getSigners();

  const SafeProxyFactory = await ethers.getContractAt(
    "ISafeProxyFactory",
    safeProxyFactoryAddr
  );

  console.log(SafeProxyFactory.target);

  const Helper = await (await ethers.getContractFactory("Helper")).deploy();

  const calldata = await Helper.returnData(
    [user.address, user2.address, user3.address],
    2
  );
  console.log(calldata);

  const salt = Math.floor(Math.random() * 10000);
  console.log(salt);

  const tx = await SafeProxyFactory.connect(user).createProxyWithNonce(
    safeImplementationAddr,
    calldata,
    salt
  );
  const receipt = await tx.wait();
  const logs = await receipt.logs;
  const data = logs[1].data;
  const safeProxyAddr = data.slice(0, 66);
  console.log(safeProxyAddr);

  const SafeProxy = await ethers.getContractAt("ISafeProxy", safeProxyAddr);

  // await SafeProxy.execTransaction(
  //   operatorAddr,
  //   ["0x", 3000000000],
  //   ethers.encodeBytes32String("")
  // );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
