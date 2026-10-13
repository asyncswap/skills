# Blink Ethereum searcher bundles

Use `@asyncswap/blink-rpc@0.0.1` for Blink, not a FlashbotsClient pointed at a
Blink URL. Verify registry availability before recommending installation;
an unpublished eth-libs checkout can build it with `bun run build:blink-rpc`.

```ts
import { BlinkEthereumClient, type Hex } from "@asyncswap/blink-rpc";

export function prepareBlink(targetHash: Hex, backrun: Hex, targetBlock: Hex) {
  const client = new BlinkEthereumClient("https://offline.invalid");
  return client.buildBundle({ txs: [targetHash, backrun], blockNumber: targetBlock });
}
```

The first entry references Blink orderflow; subsequent entries are signed
backruns. For an originator bundle use its last transaction hash after receiving
its bundle event, not a guessed grouping of individual transaction events.
Unknown target bytes mean local full-sequence simulation remains unverified.

For authorized submission configure `blinkEndpoint("ethereum", apiKey)` and
call `client.eth_sendBundle(bundle)`. It validates the returned hash, which is
not inclusion evidence. Keep URL credentials out of logs. Wire validation does
not verify signatures, chain ID, funding, nonce or profitability.

A canonical `replacementUuid` enables `buildCancellation(uuid)` and authorized
`eth_cancelBundle(uuid)`. The documented cancellation result is `200`, not a
receipt or proof that all builders revoked the bundle.

Optional identity authentication uses `X-Blink-Signature`. Build once, serialize
and sign the exact request body following Blink's documented Flashbots-style
scheme. Send that same request via `client.rpc.call(request, headers)` without
mutating its ID or contents. The raw transport bypasses wrapper validation and
sanitized `BlinkRpcError` handling; inspect errors without logging credentials.
Do not use `X-Flashbots-Signature` as an assumed replacement.

The package does not implement MEV-Share or a Blink simulation endpoint. Keep
those workflows separate. No signing, automatic retries, payments, subscriptions,
or sequencer forwarding is performed by the package.

Sources (checked 2026-10-13):
[send](https://docs.blinklabs.xyz/blink/ethereum/searchers/eth_sendbundle.md),
[cancel](https://docs.blinklabs.xyz/blink/ethereum/searchers/eth_cancelbundle.md),
[bidding and authentication](https://docs.blinklabs.xyz/blink/ethereum/searchers/integration/bid-on-transactions.md).
