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

Use `@asyncswap/blink-rpc@0.0.1` from eth-libs. During an unpublished checkout,
run `bun run build:blink-rpc` in eth-libs and use its built package locally;
verify npm availability before suggesting a registry install.
The package validates wire format, not signatures or strategy safety.

```ts
import { BlinkAttributionClient, type Hex } from "@asyncswap/blink-rpc";

export function prepareAttribution(targetHash: Hex, backruns: [Hex, ...Hex[]]) {
  const client = new BlinkAttributionClient("base", "https://offline.invalid");
  return client.buildBundle({ txs: [targetHash, ...backruns] });
}
```

This builds without network calls. For authorized attribution, configure
`blinkEndpoint("base", apiKey)` and use `client.eth_sendBundle(bundle)`.
Never log the credential-bearing URL. Attribution returns an unknown provider
result; do not treat it as an inclusion receipt. The client does not forward
transactions to the sequencer. `BlinkRpcError` exposes a code without raw
provider messages. Direct `client.rpc` calls bypass wrapper validation and
error sanitization. No automatic signing, fees, payments, or retries are added.

Robinhood uses `BlinkAttributionClient("robinhood", blinkEndpoint("robinhood", apiKey))`
with the same attribution shape but its own provider rules. Do not copy Base's
priority-fee policy onto Robinhood. See [Robinhood searcher requirements](https://docs.blinklabs.xyz/blink/robinhood-chain/searchers.md).

For simulation, build a separate `eth_simulateV1` request from decoded call
objects matching the signed transactions. Do not send raw transaction strings
as simulation calls or use attribution hashes as executable call data.

No live provider admission, key access, or sequencer execution was tested when
publishing this skill. A JSON-RPC parser response alone cannot establish them.
