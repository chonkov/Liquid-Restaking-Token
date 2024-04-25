const { ethers } = require("hardhat");

/**
 * @notice Completes a queued withdrawal through the 'Safe' wallet
 */
async function completeQueuedWithdrawal(
  signers,
  Withdrawal,
  LiquidRestakingManager,
  SafeProxy,
  Helper,
  stETHAddr,
  strategyManagerAddr,
  delegationManagerAddr,
  strategyAddr
) {
  const currentNonce = await SafeProxy.nonce();
  const to = LiquidRestakingManager.target;
  const tokens = [stETHAddr];
  const middlewareTimesIndex = 0;
  const receiveAsTokens = true;

  const stETH = await ethers.getContractAt("IWETH", stETHAddr);
  const StrategyManager = await ethers.getContractAt(
    "IStrategyManager",
    strategyManagerAddr
  );
  const DelegationManager = await ethers.getContractAt(
    "IDelegationManager",
    delegationManagerAddr
  );

  const txData = await Helper.getCompleteQueuedWithdrawalCalldata(
    to,
    Withdrawal,
    tokens,
    middlewareTimesIndex,
    receiveAsTokens,
    currentNonce
  );

  const txHash = await ethers.provider.call({
    to: SafeProxy.target,
    data: txData,
  });

  console.log(txHash);

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

  const executeTxData = await Helper.executeCompleteQueuedWithdrawalsTx(
    to,
    Withdrawal,
    tokens,
    middlewareTimesIndex,
    receiveAsTokens,
    signatures[0],
    signatures[1]
  );

  console.log(
    `Balance of Liquid Restaking Manager before completing withdrawal: ${await stETH.balanceOf(
      to
    )}`
  );
  console.log(`--------------------------------------------------------------`);

  await network.provider.send("hardhat_mine", ["0xC4E1"]);

  console.log(
    `Shares: ${await StrategyManager.stakerStrategyShares(to, strategyAddr)}`
  );

  await signers[2].sendTransaction({
    to: SafeProxy.target,
    data: executeTxData,
  });

  const withdrawalRoot = await DelegationManager.calculateWithdrawalRoot(
    Withdrawal
  );
  let isPending = await DelegationManager.pendingWithdrawals(withdrawalRoot);
  console.log(`Is ${withdrawalRoot} pending: ${isPending}`);

  console.log(
    `Shares: ${await StrategyManager.stakerStrategyShares(to, strategyAddr)}`
  );

  console.log(
    `Balance of Liquid Restaking Manager after completing withdrawal: ${await stETH.balanceOf(
      to
    )}`
  );
}

module.exports = { completeQueuedWithdrawal };
