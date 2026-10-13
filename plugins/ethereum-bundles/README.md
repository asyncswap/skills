# Ethereum bundles

Standalone Ethereum Flashbots and MEV-Share bundle preparation skill using
eth-libs. Independent of the filler and Unichain skills. Includes simulation,
authentication, bounded submission, and receipt guidance; no wallet or bot.

```text
/plugin marketplace add asyncswap/skills
/plugin install ethereum-bundles@asyncswap
```

For Codex, install the complete [skill directory](skills/ethereum-bundles/SKILL.md)
including its references. Request examples use `@asyncswap/flashbots-rpc@0.0.10`.

Blink searcher routing uses `@asyncswap/blink-rpc@0.0.1`; direct Flashbots and
MEV-Share keep their existing client. See the skill’s Blink reference.
