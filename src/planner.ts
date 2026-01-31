import { formatEther } from "ethers";
import { Config, ConsolidationPlan, TransferStep, WalletInfo } from "./types.js";

/** Gas units for a basic ETH transfer */
const ETH_TRANSFER_GAS = 21000n;
/** Gas units for an ERC-20 transfer (conservative estimate) */
const ERC20_TRANSFER_GAS = 65000n;

/**
 * Builds an optimal consolidation plan:
 *
 * 1. Identify the destination wallet
 * 2. For each non-destination wallet with tokens but insufficient ETH for gas,
 *    schedule a "fund-gas" step from the richest ETH wallet
 * 3. Schedule token sweeps from every wallet to destination
 * 4. Schedule ETH sweeps from every wallet to destination (minus gas)
 *
 * The ordering ensures gas-funding happens before token sweeps, and ETH sweeps
 * happen last (since ETH is consumed as gas in earlier steps).
 */
export function buildConsolidationPlan(
  wallets: WalletInfo[],
  destinationIndex: number,
  gasPrice: bigint,
  config: Config
): ConsolidationPlan {
  const dest = wallets[destinationIndex];
  const effectiveGasPrice = (gasPrice * BigInt(Math.round(config.gasPriceMultiplier * 100))) / 100n;
  const steps: TransferStep[] = [];

  const ethGasCost = ETH_TRANSFER_GAS * effectiveGasPrice;
  const tokenGasCost = ERC20_TRANSFER_GAS * effectiveGasPrice;

  // Track mutable ETH balances as we plan steps
  const balances = new Map<string, bigint>();
  for (const w of wallets) {
    balances.set(w.address, w.ethBalance);
  }

  const sourceWallets = wallets.filter((_, i) => i !== destinationIndex);

  // --- Phase 1: Identify wallets that need gas funding for token sweeps ---
  const gasFundingNeeded: { wallet: WalletInfo; needed: bigint }[] = [];

  for (const w of sourceWallets) {
    if (w.tokens.length === 0) continue;

    const totalTokenGas = tokenGasCost * BigInt(w.tokens.length);
    const currentBal = balances.get(w.address)!;

    if (currentBal < totalTokenGas) {
      const deficit = totalTokenGas - currentBal;
      gasFundingNeeded.push({ wallet: w, needed: deficit });
    }
  }

  // Sort by how much gas they need (smallest first for efficiency)
  gasFundingNeeded.sort((a, b) => (a.needed < b.needed ? -1 : 1));

  // Find the best gas funder: the wallet with the most ETH
  // Prefer the destination wallet as funder since it will receive everything anyway
  for (const { wallet: recipient, needed } of gasFundingNeeded) {
    // Pick funder: wallet with highest balance that can cover the cost
    const fundAmount = needed + ethGasCost; // need to fund the deficit + the cost of the funding tx itself is paid by funder
    const funder = pickBestFunder(wallets, balances, fundAmount + ethGasCost, recipient.address);

    if (!funder) {
      // No single wallet can fund this; skip these tokens (user will be warned)
      continue;
    }

    steps.push({
      type: "fund-gas",
      from: funder,
      to: recipient,
      amount: needed,
      estimatedGasCost: ethGasCost,
      description: `Send ${formatEther(needed)} ETH from wallet [${funder.index}] to wallet [${recipient.index}] for token transfer gas`,
    });

    // Update tracked balances
    balances.set(funder.address, balances.get(funder.address)! - needed - ethGasCost);
    balances.set(recipient.address, balances.get(recipient.address)! + needed);
  }

  // --- Phase 2: Sweep tokens ---
  for (const w of sourceWallets) {
    for (const token of w.tokens) {
      steps.push({
        type: "sweep-token",
        from: w,
        to: dest,
        token,
        amount: token.balance,
        estimatedGasCost: tokenGasCost,
        description: `Sweep ${token.symbol} from wallet [${w.index}] to destination`,
      });

      balances.set(w.address, balances.get(w.address)! - tokenGasCost);
    }
  }

  // --- Phase 3: Sweep remaining ETH ---
  for (const w of sourceWallets) {
    const remaining = balances.get(w.address)!;
    const sweepAmount = remaining - ethGasCost;

    if (sweepAmount <= config.dustThreshold) {
      continue; // Not worth sweeping dust
    }

    steps.push({
      type: "sweep-eth",
      from: w,
      to: dest,
      amount: sweepAmount,
      estimatedGasCost: ethGasCost,
      description: `Sweep ${formatEther(sweepAmount)} ETH from wallet [${w.index}] to destination`,
    });

    balances.set(w.address, 0n);
    balances.set(dest.address, balances.get(dest.address)! + sweepAmount);
  }

  // Summarize tokens
  const tokenTotals = new Map<string, { total: bigint; decimals: number }>();
  for (const w of sourceWallets) {
    for (const t of w.tokens) {
      const existing = tokenTotals.get(t.symbol) || { total: 0n, decimals: t.decimals };
      existing.total += t.balance;
      tokenTotals.set(t.symbol, existing);
    }
  }

  const totalGas = steps.reduce((sum, s) => sum + s.estimatedGasCost, 0n);
  const totalEth = steps.filter((s) => s.type === "sweep-eth").reduce((sum, s) => sum + s.amount, 0n);

  return {
    destination: dest,
    steps,
    totalGasEstimate: totalGas,
    totalEthToConsolidate: totalEth,
    tokensToConsolidate: Array.from(tokenTotals.entries()).map(([symbol, v]) => ({
      symbol,
      total: v.total,
      decimals: v.decimals,
    })),
  };
}

function pickBestFunder(
  wallets: WalletInfo[],
  balances: Map<string, bigint>,
  minRequired: bigint,
  excludeAddress: string
): WalletInfo | null {
  let best: WalletInfo | null = null;
  let bestBal = 0n;

  for (const w of wallets) {
    if (w.address === excludeAddress) continue;
    const bal = balances.get(w.address)!;
    if (bal >= minRequired && bal > bestBal) {
      best = w;
      bestBal = bal;
    }
  }

  return best;
}

export function formatPlan(plan: ConsolidationPlan): string {
  const lines: string[] = [];
  lines.push(`Destination: [${plan.destination.index}] ${plan.destination.address}`);
  lines.push(`Total steps: ${plan.steps.length}`);
  lines.push(`Estimated total gas: ${formatEther(plan.totalGasEstimate)} ETH`);
  lines.push(`ETH to consolidate: ${formatEther(plan.totalEthToConsolidate)} ETH`);

  if (plan.tokensToConsolidate.length > 0) {
    lines.push(`Tokens to consolidate:`);
    for (const t of plan.tokensToConsolidate) {
      const val = t.total / 10n ** BigInt(t.decimals);
      lines.push(`  ${t.symbol}: ~${val.toString()}`);
    }
  }

  lines.push(``);
  lines.push(`Execution plan:`);

  for (let i = 0; i < plan.steps.length; i++) {
    const step = plan.steps[i];
    const phase =
      step.type === "fund-gas" ? "GAS-FUND" : step.type === "sweep-token" ? "TOKEN" : "ETH";
    lines.push(`  ${i + 1}. [${phase}] ${step.description}`);
  }

  return lines.join("\n");
}
