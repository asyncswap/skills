# Base providers and simulation

Verified against linked documentation on 2026-10-13. Recheck before live use.

## Base simulation

Base documents `eth_simulateV1` on `https://mainnet.base.org` and
`https://sepolia.base.org`. Its parameters are a simulation payload and block
tag. Put dependent calls in one `blockStateCalls` entry; set `validation: true`
and use `pending` for preconfirmed state. Inspect each call's status, logs, and
return data. Record the state/time because pending state changes. Simulation
success is not submission, ordering, atomicity, or profitability evidence.

Source: [Base eth_simulateV1](https://docs.base.org/base-chain/api-reference/flashblocks-api/eth_simulateV1).

## Blink Base attribution

Blink requires searcher onboarding and an API key. Its Base searcher endpoint
is `https://baseauction.blinklabs.xyz/v1/{API_KEY}`. The attribution request's
`txs` starts with the target transaction hash followed by raw backrun bytes;
`bidWei` is ignored. Searchers separately submit both transactions to the
sequencer. This is not a Flashbots atomic relay.

Provider terms prohibit frontrunning, require matching the target priority fee,
and require a native-ETH profit share within the backrun. The page describes
both “at least 75%” and “> 75%”; resolve that ambiguity with the provider before
live participation. Verify its current payment address and calculation rules
from the source rather than hardcoding them here. Do not promise a winning bid,
ordering, privacy, or inclusion. Attribution does not replace broadcast.

Source: [Blink Base searchers](https://docs.blinklabs.xyz/blink/base/searchers.md).

The transaction-originator endpoint is a different service:
`https://base.blinklabs.xyz/v1/{API_KEY}`. Do not interchange originator and
searcher URLs or assume Ethereum relay authentication applies.

Source: [Blink Base API](https://docs.blinklabs.xyz/blink/base/api-reference.md).

## Offline eth-libs construction

Use `@asyncswap/jsonrpc@0.4.16` with a narrow provider-specific schema, rather
than `FlashbotsClient`. This example only builds an attribution request. Its
format checks do not decode signatures, authorize a backrun, or send anything.
The URL is deliberately non-routable; execution needs separately verified
provider configuration and authorization.

```ts
import { JsonRpcClient } from "@asyncswap/jsonrpc";

type AttributionSpec = {
  eth_sendBundle: {
    params: [{ txs: string[]; bidWei: string }];
    result: unknown;
  };
};
export function prepareAttribution(targetHash: string, backruns: string[]) {
  if (!/^0x[0-9a-fA-F]{64}$/.test(targetHash)) throw new Error("Invalid target hash");
  if (!backruns.length || backruns.some(tx => !/^0x(?:[0-9a-fA-F]{2})+$/.test(tx))) {
    throw new Error("Backrun bytes required; signed transaction validation is separate");
  }
  const rpc = new JsonRpcClient<AttributionSpec>("https://offline.invalid");
  return rpc.buildRequest("eth_sendBundle", [{ txs: [targetHash, ...backruns], bidWei: "0" }]);
}
```

For simulation, build a separate `eth_simulateV1` request from decoded call
objects matching the signed transactions. Do not send raw transaction strings
as simulation calls or use attribution hashes as executable call data.

No live provider admission, key access, or sequencer execution was tested when
publishing this skill. A JSON-RPC parser response alone cannot establish them.
