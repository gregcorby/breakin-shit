import { Contract, JsonRpcProvider, Wallet, formatEther } from "ethers";
import { Config, TokenBalance, WalletInfo } from "./types.js";
import { discoverTokenContracts } from "./discovery.js";

const ERC20_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
  "function transfer(address to, uint256 amount) returns (bool)",
];

const ESTIMATION_RECIPIENT = "0x000000000000000000000000000000000000dEaD";
const FALLBACK_TOKEN_GAS = 100000n;

/**
 * Enriches a discovered token contract: checks balance, fetches symbol/decimals,
 * estimates transfer gas. Returns null if balance is zero or contract is invalid.
 */
async function probeToken(
  contractAddress: string,
  walletAddress: string,
  provider: JsonRpcProvider
): Promise<TokenBalance | null> {
  try {
    const contract = new Contract(contractAddress, ERC20_ABI, provider);

    const balance: bigint = await contract.balanceOf(walletAddress);
    if (balance === 0n) return null;

    let symbol: string;
    try {
      symbol = await contract.symbol();
    } catch {
      symbol = `???_(${contractAddress.slice(0, 8)})`;
    }

    let decimals: number;
    try {
      decimals = Number(await contract.decimals());
    } catch {
      decimals = 18;
    }

    let estimatedTransferGas: bigint;
    try {
      estimatedTransferGas = await contract.transfer.estimateGas(
        ESTIMATION_RECIPIENT,
        balance
      );
      // 10% buffer on top of raw estimate
      estimatedTransferGas = (estimatedTransferGas * 110n) / 100n;
    } catch {
      estimatedTransferGas = FALLBACK_TOKEN_GAS;
    }

    return {
      contractAddress,
      symbol,
      decimals,
      balance,
      estimatedTransferGas,
    };
  } catch {
    return null;
  }
}

export async function scanWallets(
  privateKeys: string[],
  provider: JsonRpcProvider,
  config: Config,
  onProgress?: (msg: string) => void
): Promise<WalletInfo[]> {
  const network = await provider.getNetwork();
  const chainId = network.chainId;
  const wallets: WalletInfo[] = [];

  for (let i = 0; i < privateKeys.length; i++) {
    const key = privateKeys[i].trim();
    const wallet = new Wallet(key, provider);
    const address = wallet.address;

    onProgress?.(`[${i + 1}/${privateKeys.length}] ${address}`);
    const ethBalance = await provider.getBalance(address);
    onProgress?.(`  ETH: ${formatEther(ethBalance)}`);

    // Auto-discover token contracts
    onProgress?.(`  Discovering tokens...`);
    const contractAddresses = await discoverTokenContracts(address, provider, chainId);
    onProgress?.(`  Found ${contractAddresses.length} token contract(s) in history`);

    // Probe each: check balance, get metadata, estimate gas
    const tokens: TokenBalance[] = [];
    for (const ca of contractAddresses) {
      const token = await probeToken(ca, address, provider);
      if (token) {
        onProgress?.(`  ${token.symbol}: balance > 0 (gas est: ${token.estimatedTransferGas})`);
        tokens.push(token);
      }
    }

    wallets.push({
      index: i,
      privateKey: key,
      address,
      wallet,
      ethBalance,
      tokens,
    });
  }

  return wallets;
}

export function formatWalletSummary(wallets: WalletInfo[]): string {
  const lines: string[] = [];
  for (const w of wallets) {
    const ethStr = formatEther(w.ethBalance);
    lines.push(`  [${w.index}] ${w.address}`);
    lines.push(`      ETH: ${ethStr}`);
    for (const t of w.tokens) {
      const val = formatTokenAmount(t.balance, t.decimals);
      lines.push(
        `      ${t.symbol}: ${val} (${t.contractAddress.slice(0, 10)}... | gas: ${t.estimatedTransferGas})`
      );
    }
    if (w.ethBalance === 0n && w.tokens.length === 0) {
      lines.push(`      (empty)`);
    }
  }
  return lines.join("\n");
}

function formatTokenAmount(amount: bigint, decimals: number): string {
  const divisor = 10n ** BigInt(decimals);
  const whole = amount / divisor;
  const frac = amount % divisor;
  const fracStr = frac.toString().padStart(decimals, "0").slice(0, 6);
  return `${whole}.${fracStr}`;
}
