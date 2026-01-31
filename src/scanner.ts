import { Contract, JsonRpcProvider, Wallet, formatEther } from "ethers";
import { Config, TokenBalance, WalletInfo } from "./types.js";

const ERC20_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
];

export async function scanWallets(
  privateKeys: string[],
  provider: JsonRpcProvider,
  config: Config
): Promise<WalletInfo[]> {
  const wallets: WalletInfo[] = [];

  for (let i = 0; i < privateKeys.length; i++) {
    const key = privateKeys[i].trim();
    const wallet = new Wallet(key, provider);
    const address = wallet.address;

    const ethBalance = await provider.getBalance(address);

    const tokens: TokenBalance[] = [];
    for (const tokenDef of config.tokenList) {
      try {
        const contract = new Contract(tokenDef.address, ERC20_ABI, provider);
        const balance: bigint = await contract.balanceOf(address);
        if (balance > 0n) {
          tokens.push({
            contractAddress: tokenDef.address,
            symbol: tokenDef.symbol,
            decimals: tokenDef.decimals,
            balance,
          });
        }
      } catch {
        // Token contract may not exist on this network, skip
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
      lines.push(`      ${t.symbol}: ${val}`);
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
