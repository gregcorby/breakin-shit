import { JsonRpcProvider } from "ethers";

/**
 * Auto-discovers ERC-20 token contract addresses held by a wallet.
 * Tries multiple strategies in order:
 *
 * 1. Alchemy alchemy_getTokenBalances (if RPC is Alchemy)
 * 2. Etherscan tokentx history (free, no API key needed — rate-limited)
 *
 * Returns a deduplicated list of contract addresses with non-zero balances.
 */
export async function discoverTokenContracts(
  walletAddress: string,
  provider: JsonRpcProvider,
  chainId: bigint
): Promise<string[]> {
  // Strategy 1: Alchemy
  const alchemyTokens = await tryAlchemy(walletAddress, provider);
  if (alchemyTokens.length > 0) return alchemyTokens;

  // Strategy 2: Etherscan (mainnet / common testnets)
  const etherscanTokens = await tryEtherscan(walletAddress, chainId);
  if (etherscanTokens.length > 0) return etherscanTokens;

  return [];
}

async function tryAlchemy(
  address: string,
  provider: JsonRpcProvider
): Promise<string[]> {
  try {
    const result = await provider.send("alchemy_getTokenBalances", [
      address,
      "erc20",
    ]);
    if (!result?.tokenBalances) return [];

    const contracts: string[] = [];
    for (const tb of result.tokenBalances) {
      const bal = BigInt(tb.tokenBalance);
      if (bal > 0n) {
        contracts.push(tb.contractAddress.toLowerCase());
      }
    }
    return contracts;
  } catch {
    return [];
  }
}

const ETHERSCAN_DOMAINS: Record<string, string> = {
  "1": "api.etherscan.io",
  "5": "api-goerli.etherscan.io",
  "11155111": "api-sepolia.etherscan.io",
  "42161": "api.arbiscan.io",
  "10": "api-optimistic.etherscan.io",
  "137": "api.polygonscan.com",
  "8453": "api.basescan.org",
};

async function tryEtherscan(
  address: string,
  chainId: bigint
): Promise<string[]> {
  const domain = ETHERSCAN_DOMAINS[chainId.toString()];
  if (!domain) return [];

  try {
    // Fetch ERC-20 transfer history for this address (no API key = 1 req/5s rate limit)
    const url = `https://${domain}/api?module=account&action=tokentx&address=${address}&startblock=0&endblock=99999999&sort=desc&page=1&offset=1000`;

    const resp = await fetch(url);
    const data = await resp.json();

    if (data.status !== "1" || !Array.isArray(data.result)) return [];

    // Collect unique contract addresses from the tx history
    const contracts = new Set<string>();
    for (const tx of data.result) {
      if (tx.contractAddress) {
        contracts.add(tx.contractAddress.toLowerCase());
      }
    }

    return Array.from(contracts);
  } catch {
    return [];
  }
}
