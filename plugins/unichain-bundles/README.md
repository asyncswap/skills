# Unichain bundles

An independent skill for preparing Unichain single-transaction bundle requests
using eth-libs. Applies to transfers, swaps, and other specified transactions;
it does not require Async Swap orders or the filler CLI.

Includes transaction-validation guidance, request-building reference code,
execution windows, revert protection, and receipt handling. It is not a signer,
submission service, or standalone executable CLI.

Install from the marketplace:

```
/plugin marketplace add asyncswap/skills
/plugin install unichain-bundles@asyncswap
```

For local use, install or load the complete
[skill directory](skills/unichain-bundles/SKILL.md), including `references`.
Programmatic request construction uses Bun and `@asyncswap/jsonrpc@0.4.16` in
the working project. See the skill for prerequisites and execution boundaries.

The canonical skill lives here. Local Codex installations can link directly to
this directory so edits take effect without maintaining another copy.
