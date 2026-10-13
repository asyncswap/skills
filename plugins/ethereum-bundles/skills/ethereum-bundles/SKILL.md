---
name: ethereum-bundles
description: Prepare and simulate Ethereum mainnet Flashbots bundles or MEV-Share backruns using eth-libs. Use for Ethereum MEV bundle requests, relay authentication, replacement, and inclusion checks; use unichain-bundles for Unichain.
metadata:
  version: 0.1.0
---

# Ethereum bundles

Prepare Ethereum bundles independently of Async Swap filler orders. Default to
Flashbots `eth_sendBundle` for an ordered list of specified transactions. Choose
MEV-Share `mev_sendBundle` when the task involves shared orderflow or its privacy
and refund controls. Do not silently translate between formats.

Read [the relay reference](references/relay.md) for eth-libs construction,
authentication, and protocol differences. This skill supplies instructions, not
a wallet, trading strategy, background bot, or installed executable.

## Preparation

1. Establish chain, relay, intended effects, transaction order, authorized senders,
   spending and fee limits, and expiry. Default to Ethereum mainnet (chain 1)
   only for preparation; use Sepolia (11155111) when requested. Check the execution
   RPC chain ID and matching relay. Ask for missing transaction intent rather
   than inventing a trade or deploying an executor.
2. Inspect every signed transaction: recover sender and decode chain, nonce,
   destination, calldata, value, gas, fees, and access list. Compare with the
   intended operation. Reject mismatches. Handle blob and authorization-list
   transactions only with explicit support for their extra data and effects.
   Unsigned transactions are a draft, not a sendable bundle.
3. Check balances and nonce sequences per sender, including dependencies between
   transactions. Model cumulative funding, approvals, and state changes. Account
   for target-block base fee, priority fees, and explicit builder payments.
   Preserve contract-enforced deadlines and minimum outputs; a relay window
   does not enforce a transaction deadline on-chain.
4. Choose a near-future target and a finite retry horizon within the user's
   authorization. Refresh state, fees, and simulation when the head changes.
   Keep economic estimates separate from guaranteed outcomes; if comparing
   Async Swap fills, express values in USDC and include execution costs.
5. Simulate the ordered bundle with the selected protocol. Separate local/fork
   simulation from relay simulation: relay simulation discloses signed bytes
   and needs permission to share them with that endpoint. Individual `eth_call`
   successes do not establish that the combined bundle works. Inspect every
   result, gas use, expected transfers, and state changes. Missing orderflow
   bytes or failed simulation means the bundle is not verified.
6. Return a reviewable manifest: chain/relay, sender and nonce sequence,
   transaction hashes and effects, fees/value at risk, simulation block/result,
   target/expiry, revert policy, and unresolved assumptions. Store signed payloads
   locally with restricted permissions; omit them from public logs and commits.

## Submission and lifecycle

Preparation does not authorize transaction signing or submission. Use the user's
approved wallet and keep the relay identity signer separate from transaction
signers. Never ask for keys or seed phrases in chat. Existing authorization can
cover execution and bounded retries; do not repeatedly ask within that scope.

Before sending, verify the exact serialized request, relay authentication,
current target window, and authorized financial limits. Default to no permitted
reverts. Allowing a revert can leave other transactions included and paid for;
it requires an intentional, reviewed dependency model.

Stop at the approved expiry, spend limit, invalid nonce, failed simulation, or
changed intended effects. Do not switch to public submission, add builders,
share extra hints, or extend retries without authorization covering the change.
A bundle hash is acceptance, not inclusion. Verify transaction receipts, status,
block placement/order, and resulting application state; report pending,
expired, reverted, and confirmed separately. Recheck after reorgs.

Replacement/cancellation is relay-specific and is not a way to revoke a signed
transaction everywhere. Anyone with signed bytes may submit them elsewhere.
