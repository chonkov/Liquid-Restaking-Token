const { ethers } = require("hardhat");

async function deploySafe(
  signers,
  safeProxyFactoryAddr,
  safeImplementationAddr
) {
  const [signer1, signer2, signer3] = signers;

  const SafeProxyFactory = await ethers.getContractAt(
    "ISafeProxyFactory",
    safeProxyFactoryAddr
  );

  console.log(SafeProxyFactory.target);

  const Helper = await (await ethers.getContractFactory("Helper")).deploy();

  const initializationData = await Helper.returnData(
    [signer1.address, signer2.address, signer3.address],
    2
  );
  // console.log(initializationData);

  const salt = Math.floor(Math.random() * 10000);
  // console.log(salt);

  const tx = await SafeProxyFactory.connect(signer1).createProxyWithNonce(
    safeImplementationAddr,
    initializationData,
    salt
  );
  const receipt = await tx.wait();
  const logs = await receipt.logs;
  const data = logs[1].data;
  const safeProxyAddr = "0x" + data.slice(26, 66);
  console.log(logs[1].data);
  console.log(safeProxyAddr);

  const SafeProxy = await ethers.getContractAt("ISafeProxy", safeProxyAddr);

  return SafeProxy;
}

module.exports = { deploySafe };
