# Ethereum relay reference

Checked 2026-10-13. Recheck provider documentation before live execution.

## Protocol selection

Flashbots mainnet relay: `https://relay.flashbots.net`; Sepolia:
`https://relay-sepolia.flashbots.net`. Use a separate execution RPC for state.

For `eth_sendBundle`, supply ordered signed `txs` and a hex `blockNumber`.
Optional timestamp bounds supplement the block target. Omit
`revertingTxHashes` by default. Current limits are 100 transactions and
300,000 bytes. Simulate using `eth_callBundle` with the same transactions,
target block, and explicit `stateBlockNumber`.

Use a fresh `replacementUuid` for each independently managed classic bundle;
reuse it only to replace that bundle. `eth_cancelBundle` requires the original
UUID. Cancellation does not undo inclusion or guarantee withdrawal everywhere.

Source: [Flashbots RPC](https://docs.flashbots.net/flashbots-auction/advanced/rpc-endpoint).

MEV-Share uses `version: "v0.1"`, `inclusion.block` and optional `maxBlock`,
and a `body` containing hash references, signed transactions with `canRevert`,
or nested bundles. Default `canRevert` to false. The relay currently permits
only one backrun transaction; do not confuse this with Unichain's one-transaction
bundle rule. Hash references are not signed bytes. Do not claim to have locally
simulated unavailable transactions.

Privacy hints expose information; choose them deliberately. Builder selection
is constrained by constituent orderflow preferences, and Flashbots is included
by default. Refund settings affect recipients and proceeds: never invent them.
Use `mev_simBundle` through a compatible client, checking the current API's
parameter shape; it is not `eth_callBundle` with a renamed method. Do not assume
classic replacement/cancellation fields apply.

Sources: [MEV-Share bundles](https://docs.flashbots.net/flashbots-mev-share/searchers/understanding-bundles),
[RPC limits and simulation](https://docs.flashbots.net/flashbots-auction/advanced/rpc-endpoint).

## eth-libs preparation

The published `@asyncswap/flashbots-rpc@0.0.10` supplies `FlashbotsClient` and
method types. Inspect the installed version before relying on its MEV-Share
simulation types: local 0.0.10 describes two parameters, while the RPC page's
schema and example differ. Resolve against the current official client/spec;
do not cast away a mismatch and label it tested.

Use the project’s package manager to install the pinned package if needed.
With already validated signed transactions, request construction is offline:

```ts
import { FlashbotsClient, type Hex } from "@asyncswap/flashbots-rpc";

export function prepareClassic(txs: Hex[], targetBlock: bigint, stateBlock: bigint) {
  const client = new FlashbotsClient("https://relay.flashbots.net");
  const blockNumber = `0x${targetBlock.toString(16)}` as Hex;
  return {
    simulation: client.rpc.buildRequest("eth_callBundle", [{
      txs, blockNumber,
      stateBlockNumber: `0x${stateBlock.toString(16)}` as Hex,
    }]),
    submission: client.rpc.buildRequest("eth_sendBundle", [{ txs, blockNumber }]),
  };
}
```

This helper only assembles requests; it neither validates signed transactions
nor simulates, signs, or sends them. Validation remains required by SKILL.md.

## Authentication without body drift

Serialize the request exactly once. With an authorized ethers-compatible
identity signer, compute `await authSigner.signMessage(id(body))`, where `id`
is ethers' UTF-8 keccak256 helper and `body` is that serialized string. Send
`X-Flashbots-Signature: <identity-address>:<signature>` with precisely that body.
Do not sign raw digest bytes instead of the hex string. Rebuilding a request
can change its ID or serialization and invalidate authentication. Use the same
identity for managing its bundle lifecycle. Never copy demo private keys into
live examples.

Source: [Flashbots authentication](https://docs.flashbots.net/flashbots-auction/advanced/rpc-endpoint#authentication).
Library: [eth-libs Flashbots package](https://github.com/asyncswap/eth-libs/tree/main/packages/flashbots-rpc).
