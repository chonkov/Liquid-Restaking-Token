const { ethers } = require("hardhat");

/**
 * @notice Delegates to an operator via 'Safe' wallet
 */
async function delegateTo(
  signers,
  Helper,
  SafeProxy,
  LiquidRestakingManager,
  delegationManagerAddr,
  operatorAddr
) {
  const currentNonce = await SafeProxy.nonce();

  const to = LiquidRestakingManager.target;

  const txData = await Helper.getDelegateToCalldata(
    to,
    operatorAddr,
    currentNonce
  );

  const txHash = await ethers.provider.call({
    to: SafeProxy.target,
    data: txData,
  });

  const signatures = [];
  for (let i = 1; i <= 2; i++) {
    const signature = await signers[i].signMessage(ethers.getBytes(txHash));
    const v = signature.slice(130);
    let newV;
    if (v == "1b") newV = "1f";
    else if (v == "1c") newV = "20";

    const newSignature = signature.slice(0, 130) + newV;
    signatures.push(newSignature);
  }

  const executeTxData = await Helper.executeDelegateToTx(
    to,
    operatorAddr,
    signatures[0],
    signatures[1]
  );

  const DelegationManager = await ethers.getContractAt(
    "IDelegationManager",
    delegationManagerAddr
  );

  console.log(
    `'LiquidRestakingManager' delegated: ${await DelegationManager.isDelegated(
      to
    )}`
  );

  await signers[0].sendTransaction({
    to: SafeProxy.target,
    data: executeTxData,
  });

  console.log(
    `'LiquidRestakingManager' delegated: ${await DelegationManager.isDelegated(
      to
    )}`
  );
}

module.exports = { delegateTo };
