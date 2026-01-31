import { Config } from "./types.js";

export const DEFAULT_CONFIG: Config = {
  rpcUrl: "https://eth.llamarpc.com",
  /** Gas price multiplier for safety margin (e.g. 1.25 = 25% buffer) */
  gasPriceMultiplier: 1.25,
  /** Minimum ETH balance (wei) to bother sweeping */
  dustThreshold: 10000000000000n, // 0.00001 ETH
};
