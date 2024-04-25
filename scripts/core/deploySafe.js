const { ethers } = require("hardhat");

/**
 * @notice Deploys `Safe` wallet through the `Factory`
 */
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

  const Helper = await (await ethers.getContractFactory("Helper")).deploy();

  /**
   * @notice Calldata to pass to `setup` inside `Safe.sol` contract
   */
  const initializationData = await Helper.initCalldata(
    [signer1.address, signer2.address, signer3.address],
    2
  );

  const salt = Math.floor(Math.random() * 10000);

  const tx = await SafeProxyFactory.connect(signer1).createProxyWithNonce(
    safeImplementationAddr,
    initializationData,
    salt
  );

  /**
   * @notice Extract the address of newly created `SafeProxy`
   */
  const receipt = await tx.wait();
  const logs = await receipt.logs;
  const data = logs[1].data;
  const safeProxyAddr = "0x" + data.slice(26, 66);
  console.log(`Address of created 'SafeProxy': ${safeProxyAddr}`);

  const SafeProxy = await ethers.getContractAt("ISafeProxy", safeProxyAddr);

  return SafeProxy;
}

module.exports = { deploySafe };
