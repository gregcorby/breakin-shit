import { stdin, stdout } from "node:process";
import * as readline from "node:readline";
import { JsonRpcProvider, formatEther, Wallet } from "ethers";
import { DEFAULT_CONFIG } from "./config.js";
import { scanWallets, formatWalletSummary } from "./scanner.js";
import { buildConsolidationPlan, formatPlan } from "./planner.js";
import { executePlan } from "./executor.js";
import { Config } from "./types.js";

// ---------------------------------------------------------------------------
// Minimal CLI helpers (no heavy deps needed)
// ---------------------------------------------------------------------------
const rl = readline.createInterface({ input: stdin, output: stdout });
const ask = (q: string): Promise<string> =>
  new Promise((resolve) => rl.question(q, (a) => resolve(a.trim())));

function log(msg: string) {
  console.log(msg);
}

function header(msg: string) {
  console.log(`\n${"=".repeat(60)}`);
  console.log(`  ${msg}`);
  console.log(`${"=".repeat(60)}\n`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  header("ETH Wallet Consolidator");

  // --- RPC URL ---
  const customRpc = await ask(
    `RPC URL (press Enter for default: ${DEFAULT_CONFIG.rpcUrl}): `
  );
  const config: Config = {
    ...DEFAULT_CONFIG,
    rpcUrl: customRpc || DEFAULT_CONFIG.rpcUrl,
  };

  const provider = new JsonRpcProvider(config.rpcUrl);

  // Verify connection
  try {
    const network = await provider.getNetwork();
    log(`Connected to chain ${network.chainId} (${network.name})`);
  } catch (err) {
    log(`ERROR: Could not connect to RPC at ${config.rpcUrl}`);
    log((err as Error).message);
    process.exit(1);
  }

  // --- Collect private keys ---
  header("Enter Private Keys");
  log("Paste private keys one per line. Enter a blank line when done.");
  log("Keys are NEVER stored to disk — they exist only in memory.\n");

  const privateKeys: string[] = [];
  let keyNum = 1;
  while (true) {
    const key = await ask(`  Key #${keyNum}: `);
    if (!key) break;

    // Validate
    try {
      const w = new Wallet(key);
      log(`    -> ${w.address}`);
      privateKeys.push(key);
      keyNum++;
    } catch {
      log(`    -> Invalid key, skipping.`);
    }
  }

  if (privateKeys.length < 2) {
    log("\nNeed at least 2 wallets to consolidate. Exiting.");
    rl.close();
    process.exit(0);
  }

  // --- Scan wallets ---
  header("Scanning Wallets");
  log("Fetching ETH and token balances...\n");

  const wallets = await scanWallets(privateKeys, provider, config);
  log(formatWalletSummary(wallets));

  const nonEmpty = wallets.filter(
    (w) => w.ethBalance > 0n || w.tokens.length > 0
  );
  if (nonEmpty.length === 0) {
    log("\nAll wallets are empty. Nothing to consolidate.");
    rl.close();
    process.exit(0);
  }

  // --- Pick destination ---
  header("Choose Destination Wallet");
  log("Which wallet should receive all funds?\n");
  for (const w of wallets) {
    log(`  [${w.index}] ${w.address} (${formatEther(w.ethBalance)} ETH)`);
  }
  log("");

  let destIndex = -1;
  while (destIndex < 0 || destIndex >= wallets.length) {
    const ans = await ask(`Destination wallet index [0-${wallets.length - 1}]: `);
    destIndex = parseInt(ans, 10);
    if (isNaN(destIndex)) destIndex = -1;
  }

  // --- Build plan ---
  header("Building Consolidation Plan");

  const feeData = await provider.getFeeData();
  const gasPrice = feeData.gasPrice ?? feeData.maxFeePerGas ?? 0n;
  log(`Current gas price: ${formatEther(gasPrice * 1000000n)} Gwei (approx)\n`);

  const plan = buildConsolidationPlan(wallets, destIndex, gasPrice, config);

  if (plan.steps.length === 0) {
    log("No transfers needed — destination already has all funds, or balances are below dust threshold.");
    rl.close();
    process.exit(0);
  }

  log(formatPlan(plan));

  // --- Confirm ---
  header("Confirm Execution");
  const confirm = await ask("Execute this plan? (yes/no): ");
  if (confirm.toLowerCase() !== "yes" && confirm.toLowerCase() !== "y") {
    log("Aborted.");
    rl.close();
    process.exit(0);
  }

  // --- Execute ---
  header("Executing Transfers");

  const result = await executePlan(plan, provider, {
    onStepStart(i, step) {
      log(`\n[${i + 1}/${plan.steps.length}] ${step.description}`);
      log(`  Sending transaction...`);
    },
    onStepComplete(i, txHash) {
      log(`  TX: ${txHash}`);
    },
    onStepError(i, error) {
      log(`  FAILED: ${error.message}`);
    },
  });

  // --- Summary ---
  header("Done");
  log(`Succeeded: ${result.succeeded}`);
  log(`Failed:    ${result.failed}`);
  if (result.txHashes.length > 0) {
    log(`\nTransaction hashes:`);
    for (const h of result.txHashes) {
      log(`  ${h}`);
    }
  }

  rl.close();
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
