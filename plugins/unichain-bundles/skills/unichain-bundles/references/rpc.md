# Unichain bundle RPC

Verified against [Unichain's bundle documentation](https://developers.uniswap.org/docs/unichain/technical-information/advanced-txn) on 2026-10-13. Recheck that primary source before relying on changed capabilities.

| Property | Current documented behavior |
| --- | --- |
| Chain | Unichain mainnet, 130 |
| Endpoint | `https://mainnet.unichain.org` |
| Method | `eth_sendBundle` |
| `txs` | Exactly one serialized signed transaction |
| Block range | `minBlockNumber`, `maxBlockNumber`, hex strings |
| Timestamp range | `minTimestamp`, `maxTimestamp`, Unix-second numbers |
| Range choice | Block and timestamp ranges are mutually exclusive |
| Revert protection | Omit `revertingTxHashes` |
| Cancellation | Not supported |
| Receipt identifier | Returned `bundleHash` equals the transaction hash |

Use explicit bounds instead of relying on the default lifetime. The initial skill
workflow uses timestamps. Both ends are inclusive. For a quote expiring at `T`
with exclusive semantics, use `maxTimestamp <= T - 1`.

## Build with eth-libs

Use [`@asyncswap/jsonrpc`](https://github.com/asyncswap/eth-libs/tree/main/packages/jsonrpc),
tested here at version 0.4.16. The Ethereum `FlashbotsClient` schema is not a
substitute for Unichain's schema. Dependency setup, when needed in an authorized
project, is `bun add --exact @asyncswap/jsonrpc@0.4.16`.

The following builder is the final serialization step **after** verifying the
signed transaction and simulating its intended effects. It does not do those
checks, authenticate a quote, sign, or submit.

```ts
import { JsonRpcClient } from "@asyncswap/jsonrpc";

type Hex = `0x${string}`;
type UnichainMethods = {
  eth_sendBundle: {
    params: [{ txs: [Hex]; minTimestamp: number; maxTimestamp: number }];
    result: { bundleHash: Hex };
  };
};

export function buildRequest(
  verifiedSignedTransaction: Hex,
  minTimestamp: number,
  maxTimestamp: number,
) {
  const now = Math.floor(Date.now() / 1000);
  if (!/^0x02(?:[0-9a-fA-F]{2})+$/.test(verifiedSignedTransaction)) {
    throw new Error("Expected a serialized EIP-1559 transaction");
  }
  if (!Number.isSafeInteger(minTimestamp) || !Number.isSafeInteger(maxTimestamp) ||
      minTimestamp < now || maxTimestamp <= minTimestamp || maxTimestamp - now > 30) {
    throw new Error("Refresh preparation and choose a short future window");
  }
  const rpc = new JsonRpcClient<UnichainMethods>("https://mainnet.unichain.org");
  return rpc.buildRequest("eth_sendBundle", [{
    txs: [verifiedSignedTransaction], minTimestamp, maxTimestamp,
  }]);
}
```

Never use an unsigned transaction object or its calldata in `txs`. A hex-format
check alone does not prove that a transaction is signed or matches user intent.
Decode it and recover its signer with the project's Ethereum transaction library
before invoking this builder. Keep the original signed bytes intact.

## Simulation and costs

Use the configured chain RPC's `eth_call` and `eth_estimateGas` for the intended
transaction. No bundle simulation method is established by this reference; do
not assume Ethereum's `eth_callBundle` is supported on Unichain.

Check the pending nonce and affordability of value plus the signed maximum gas
charge. Execution gas alone is not a complete fee model: include applicable L1
data fees and other chain charges. For trades, compare total costs with the
strategy's valuation. Revert protection does not guarantee inclusion or profit.

## After separately authorized submission

Read the JSON-RPC `error` or `result` explicitly. If accepted, query
`eth_getTransactionReceipt` using `result.bundleHash`. Require a successful
receipt and verify the application effect before reporting completion.

The documented dropped-bundle error uses code `-32602`; inspect its message and
window context because that code can also represent invalid parameters. A null
receipt can mean pending or unavailable. Bundles may expire without inclusion.
Do not claim success or blindly resubmit based on either case.
