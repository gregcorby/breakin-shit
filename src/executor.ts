import { Contract, JsonRpcProvider, Wallet, formatEther, parseUnits } from "ethers";
import { ConsolidationPlan, TransferStep } from "./types.js";

const ERC20_ABI = [
  "function transfer(address to, uint256 amount) returns (bool)",
  "function balanceOf(address) view returns (uint256)",
];

export interface ExecutionCallbacks {
  onStepStart: (stepIndex: number, step: TransferStep) => void;
  onStepComplete: (stepIndex: number, txHash: string) => void;
  onStepError: (stepIndex: number, error: Error) => void;
}

export async function executePlan(
  plan: ConsolidationPlan,
  provider: JsonRpcProvider,
  callbacks: ExecutionCallbacks
): Promise<{ succeeded: number; failed: number; txHashes: string[] }> {
  let succeeded = 0;
  let failed = 0;
  const txHashes: string[] = [];

  for (let i = 0; i < plan.steps.length; i++) {
    const step = plan.steps[i];
    callbacks.onStepStart(i, step);

    try {
      const txHash = await executeStep(step, provider);
      txHashes.push(txHash);
      succeeded++;
      callbacks.onStepComplete(i, txHash);
    } catch (err) {
      failed++;
      callbacks.onStepError(i, err as Error);

      // If a gas-funding step fails, skip dependent token sweeps from that wallet
      if (step.type === "fund-gas") {
        const targetAddr = step.to.address;
        // Find and skip subsequent token sweeps from the wallet we failed to fund
        while (
          i + 1 < plan.steps.length &&
          plan.steps[i + 1].type === "sweep-token" &&
          plan.steps[i + 1].from.address === targetAddr
        ) {
          i++;
          failed++;
          callbacks.onStepError(i, new Error("Skipped: gas funding failed"));
        }
      }
    }
  }

  return { succeeded, failed, txHashes };
}

async function executeStep(step: TransferStep, provider: JsonRpcProvider): Promise<string> {
  const signer = new Wallet(step.from.privateKey, provider);

  if (step.type === "fund-gas" || step.type === "sweep-eth") {
    return await sendEth(signer, step.to.address, step.amount, provider);
  }

  if (step.type === "sweep-token" && step.token) {
    return await sendToken(signer, step.to.address, step.token.contractAddress, step.token.balance, provider);
  }

  throw new Error(`Unknown step type: ${step.type}`);
}

async function sendEth(
  signer: Wallet,
  to: string,
  amount: bigint,
  provider: JsonRpcProvider
): Promise<string> {
  // For sweep-eth, recalculate to send max minus gas at current prices
  const feeData = await provider.getFeeData();
  const gasPrice = feeData.gasPrice ?? feeData.maxFeePerGas ?? 0n;

  // Check actual balance at execution time
  const balance = await provider.getBalance(signer.address);
  const gasCost = 21000n * gasPrice;

  // Use the smaller of planned amount vs (actual balance - gas)
  let sendAmount = amount;
  if (sendAmount + gasCost > balance) {
    sendAmount = balance - gasCost;
  }

  if (sendAmount <= 0n) {
    throw new Error(`Insufficient balance for transfer. Balance: ${formatEther(balance)}, gas cost: ${formatEther(gasCost)}`);
  }

  const tx = await signer.sendTransaction({
    to,
    value: sendAmount,
    gasLimit: 21000n,
  });

  const receipt = await tx.wait();
  if (!receipt || receipt.status === 0) {
    throw new Error(`Transaction reverted: ${tx.hash}`);
  }

  return tx.hash;
}

async function sendToken(
  signer: Wallet,
  to: string,
  tokenAddress: string,
  amount: bigint,
  provider: JsonRpcProvider
): Promise<string> {
  const contract = new Contract(tokenAddress, ERC20_ABI, signer);

  // Re-check actual token balance at execution time
  const actualBalance: bigint = await contract.balanceOf(signer.address);
  const sendAmount = actualBalance < amount ? actualBalance : amount;

  if (sendAmount === 0n) {
    throw new Error("Token balance is 0");
  }

  const tx = await contract.transfer(to, sendAmount);
  const receipt = await tx.wait();
  if (!receipt || receipt.status === 0) {
    throw new Error(`Token transfer reverted: ${tx.hash}`);
  }

  return tx.hash;
}
