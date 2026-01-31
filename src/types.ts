import { Wallet } from "ethers";

export interface WalletInfo {
  index: number;
  privateKey: string;
  address: string;
  wallet: Wallet;
  ethBalance: bigint;
  tokens: TokenBalance[];
}

export interface TokenBalance {
  contractAddress: string;
  symbol: string;
  decimals: number;
  balance: bigint;
  /** Gas units estimated via eth_estimateGas for this specific transfer */
  estimatedTransferGas: bigint;
}

export interface TransferStep {
  type: "fund-gas" | "sweep-eth" | "sweep-token";
  from: WalletInfo;
  to: WalletInfo;
  /** For token transfers */
  token?: TokenBalance;
  /** Amount in wei (ETH) or token smallest unit */
  amount: bigint;
  /** Estimated gas cost in wei */
  estimatedGasCost: bigint;
  description: string;
}

export interface ConsolidationPlan {
  destination: WalletInfo;
  steps: TransferStep[];
  totalGasEstimate: bigint;
  totalEthToConsolidate: bigint;
  tokensToConsolidate: { symbol: string; total: bigint; decimals: number }[];
}

export interface Config {
  rpcUrl: string;
  /** Gas price multiplier for safety margin (e.g. 1.25 = 25% buffer) */
  gasPriceMultiplier: number;
  /** Minimum ETH balance (wei) to bother sweeping */
  dustThreshold: bigint;
}
