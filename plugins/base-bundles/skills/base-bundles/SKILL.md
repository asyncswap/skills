---
name: base-bundles
description: Prepare Base transaction sequences, simulate them against Flashblocks state, and construct provider-specific attribution bundles using eth-libs. Use for Base MEV bundles and backruns; do not assume Ethereum Flashbots atomic submission semantics.
metadata:
  version: 0.1.1
---

# Base bundles

Prepare Base workflows independently of Async Swap. Read
[the provider reference](references/providers.md) before choosing a transport.
Use `@asyncswap/blink-rpc@0.0.1` for Blink attribution construction and explicit
submission. This skill is guidance, not a signer or bot.

## Choose the execution model

Establish whether the user needs an atomic transaction, an ordered simulation,
or a provider-specific searcher workflow. Confirm Base mainnet (8453) or Base
Sepolia (84532) from the execution RPC. Mainnet provider support does not imply
Sepolia support. Check current provider documentation and access requirements.

Base's documented `eth_simulateV1` simulates sequences; it does not submit them.
Blink's documented Base `eth_sendBundle` records attribution; it does not submit
the target and backrun for the searcher. Neither establishes atomic inclusion.
Do not copy Ethereum Flashbots or Unichain schemas because a method name matches.

If atomic execution is essential and no verified provider offers it, prepare a
single transaction through an existing reviewed executor or wallet that enforces
all-or-nothing behavior. Inspect failure handling, caller identity, approvals,
and value forwarding. A multicall that tolerates failed subcalls is not enough.
Do not deploy an executor or weaken atomicity without authorization.

## Prepare and evaluate

- Record intended calls, order, sender, token addresses, amounts, slippage,
  deadlines, fee ceiling, and any provider payment. Ask for missing intent;
  never infer a profitable trade from a target hash alone.
- Recover signers and decode signed transactions. Check chain, nonce sequence,
  destination, calldata, value, gas, fee caps, access lists, and dependencies.
  Reject mismatches; extra transaction types require support for their effects.
- Simulate dependent calls together against a named state. Preserve nonce and
  balance validation. State overrides can explore scenarios but do not prove
  real funding, allowances, or deployability. Unknown target bytes prevent
  verification of a backrun's prerequisites.
- Include L2 execution, L1 data, applicable operator/provider fees, and payments
  in cost estimates. Use current chain fee tooling, not Ethereum gas alone.
  Express Async Swap comparisons in USDC without assuming test tokens have
  redeemable dollar value.
- Require on-chain bounds on the strategy's outcomes. Separate sequencer
  submissions can reorder, land alone, or fail independently; fees may still
  be spent. A successful simulation does not remove that exposure.

Return a manifest identifying the network, provider, exact effects, funding,
simulation state/results, transaction hashes, expiry/retry limit, and atomicity
limitations. Keep unsigned drafts distinct from validated signed payloads.

## Authorization and completion

Preparation is read-only. User authorization must cover wallet signing,
disclosure of signed bytes to a simulation provider, attribution, actual
sequencer submission, and financial limits as applicable. Reuse existing
explicit authorization within its scope; never treat attribution approval as
permission to send a trade. Keep keys and API credentials out of chat/logs.

Do not create provider accounts, accept searcher terms, add profit transfers,
or change endpoints on the user's behalf without authorization covering that
action. Provider obligations must be reviewed before live participation.

Stop at the approved deadline, changed intent, invalid nonce, failed simulation,
or exceeded budget. Never silently fall back to public submission or retry
indefinitely. Check receipts and application state for every submitted transaction;
report partial inclusion explicitly. Preconfirmation and provider acceptance
are not final settlement. Recheck inclusion after reorgs.
