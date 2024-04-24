const { ethers } = require("hardhat");

/**
 * @notice Queues a withdrawal through the 'Safe' wallet
 */
async function queueWithdrawal(
  signers,
  Helper,
  SafeProxy,
  LiquidRestakingManager,
  strategyAddr,
  strategyManagerAddr,
  delegationManagerAddr,
  operatorAddr
) {
  const currentNonce = await SafeProxy.nonce();
  const to = LiquidRestakingManager.target;
  const StrategyManager = await ethers.getContractAt(
    "IStrategyManager",
    strategyManagerAddr
  );
  let totalShares = await StrategyManager.stakerStrategyShares(
    to,
    strategyAddr
  );

  console.log(`--------------------------------------------------------------`);
  console.log(
    `Total shares owned by 'LiquidRestakingManager' contract before queued withdrawal: ${totalShares}`
  );

  const txData = await Helper.getQueueWithdrawalCalldata(
    to,
    [[strategyAddr]],
    [[totalShares]],
    [to],
    currentNonce
  );

  const txHash = await ethers.provider.call({
    to: SafeProxy.target,
    data: txData,
  });

  const signatures = [];
  for (let i = 0; i <= 2; i += 2) {
    const signature = await signers[i].signMessage(ethers.getBytes(txHash));
    const v = signature.slice(130);
    let newV;
    if (v == "1b") newV = "1f";
    else if (v == "1c") newV = "20";

    const newSignature = signature.slice(0, 130) + newV;
    signatures.push(newSignature);
  }

  const executeTxData = await Helper.executeQueueWithdrawalsTx(
    to,
    [[strategyAddr]],
    [[totalShares]],
    [to],
    signatures[0],
    signatures[1]
  );

  const DelegationManager = await ethers.getContractAt(
    "IDelegationManager",
    delegationManagerAddr
  );

  const blockNumber = await Helper.blockNumber();
  const withdrawalRoot = await DelegationManager.calculateWithdrawalRoot([
    to,
    operatorAddr,
    to,
    0,
    parseInt(blockNumber) + 1,
    [strategyAddr],
    [totalShares],
  ]);
  let isPending = await DelegationManager.pendingWithdrawals(withdrawalRoot);
  console.log(`Is ${withdrawalRoot} pending: ${isPending}`);

  await signers[2].sendTransaction({
    to: SafeProxy.target,
    data: executeTxData,
  });

  isPending = await DelegationManager.pendingWithdrawals(withdrawalRoot);
  console.log(`Is ${withdrawalRoot} pending: ${isPending}`);

  totalShares = await StrategyManager.stakerStrategyShares(to, strategyAddr);

  console.log(`--------------------------------------------------------------`);
  console.log(
    `Total shares owned by 'LiquidRestakingManager' contract after queued withdrawal: ${totalShares}`
  );
}

module.exports = { queueWithdrawal };
