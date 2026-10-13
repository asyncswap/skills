---
name: unichain-bundles
description: Prepare Unichain single-transaction bundles with execution windows and revert protection using eth-libs. Use for transfers, swaps, arbitrage, or other already specified transactions; independent of Async Swap filler orders.
metadata:
  version: 0.1.0
---

# Unichain bundles

Prepare a bounded `eth_sendBundle` request for an intended transaction on Unichain mainnet (chain 130). This skill is independent of Async Swap: it requires neither a filler order nor the filler CLI. It does not decide whether an arbitrary trade is profitable or grant wallet signing authority.

Read [the RPC reference](references/rpc.md) for the eth-libs request builder, current Unichain constraints, and receipt handling. Use a project with Bun and `@asyncswap/jsonrpc` installed when constructing requests programmatically. The skill itself is guidance and reference code, not a signer or an installed bundle CLI.

## Prepare

1. Establish the exact intended transaction: sender, chain, destination, calldata, value, and any contract-enforced payment/slippage bounds. Use user-approved wallet and RPC configuration. Check the RPC chain ID. Do not reinterpret arbitrary calldata as an approved trade.
2. Read current chain state, sender balances, and pending nonce. Simulate the exact call from that sender with its value, calldata, gas, fees, and access list where applicable. Estimate execution gas and account separately for L1 data fees and other chain charges. Report the block reference. A failed or stale simulation prevents recommending submission.
3. Choose a short timestamp window. Default to five seconds for immediate execution, and cap the end before any quote or intent expiry. Timestamp bounds are inclusive; an exclusive quote expiry must be reduced by one second. If there is insufficient time to sign and submit, obtain a fresh quote. Do not silently extend its validity.
4. If unsigned, return the unsigned transaction and proposed window; explain that there is no sendable bundle request yet. Have the authorized wallet fill nonce/gas/fees and sign. Never request private keys or seed phrases.
5. If signed bytes are supplied, decode the transaction and recover its sender. Verify chain ID 130, sender, destination, calldata, value, nonce, and approved fee limits against the intended transaction. For the initial workflow use EIP-1559 transactions; do not silently accept blob or authorization-list transaction types with additional effects. Re-simulate with the signed gas/fees/access list and refresh state and expiry checks before building the request.
6. Use eth-libs' `JsonRpcClient.buildRequest` with the Unichain-specific schema from the reference. Include exactly one signed transaction and the timestamp range. Omit `revertingTxHashes` to retain revert protection. Building a request makes no network call.

## Execution boundaries

- Keep preparation read-only unless the user explicitly authorizes the specific live transaction. Supplying signed bytes or asking to prepare a bundle is not permission to broadcast. A signing wallet and submission transport are separate from this skill.
- Unichain currently allows one transaction per bundle. A separate approval and swap cannot both be included. Handle prerequisites separately, or use an already reviewed executor that performs the intended steps within one transaction; never invent an executor deployment.
- Do not mix timestamp and block ranges. Do not reuse the Ethereum Flashbots schema, relay authentication, `builders`, replacement UUIDs, or cancellation methods for this endpoint.
- There is no documented bundle cancellation. After expiry, re-evaluate and obtain authorization for any retry that changes the approved transaction. Do not automatically switch to public transaction submission or another relay.
- Call simulation is not bundle simulation, admission, inclusion, or a privacy guarantee. The RPC window is not signed into the transaction: anyone holding the signed bytes may be able to broadcast them through another path. Do not put signed transactions in public logs or commits.
- After an authorized send, verify receipt status and the application's resulting state. A returned bundle hash is not completion. Report expiry, reverts, RPC errors, and pending status separately; do not equate all missing receipts with expiry.

## With an Async Swap fill

If the separate `asyncswap-filler` skill is installed, use its order validation, USDC valuation, and `prepare-bundle` tool for fills. That adapter implements the request construction and signed-fill checks. This skill supplies the chain-level bundle rules; it must not bypass filler payment limits, required approvals, or quote freshness.
