# asyncswap/skills

Claude Code plugins and skills by [asyncswap](https://github.com/asyncswap).

## Installation

```
/plugin marketplace add asyncswap/skills
```

## Plugins

### Solidity LSP

Language server support for Solidity via [solidity-language-server](https://github.com/asyncswap/solidity-language-server). Adds skills for security review, call/entrypoint analysis, PoC generation, and code cleanup driven by live LSP diagnostics.

```
/plugin install solidity-language-server@asyncswap
```

### lsp-bench

Test, validate, and benchmark performance of LSP servers using only YAML. Helps you write [lsp-bench](https://github.com/asyncswap/lsp-bench) configs for performance benchmarks, response assertions, multi-file consistency checks, benches across file edits, file-operation lifecycle tests, and side-by-side LSP version comparisons. Manage how the LSP is run — restart it for every benchmark (cold) or reuse one initialized session across multiple steps (warm).

```
/plugin install lsp-bench@asyncswap
```

### Async Swap filler

Discover orders, evaluate supplied USDC valuations, and prepare fills or Unichain single-transaction bundles. The tools do not sign or broadcast. Requires Bun and a checkout containing the current filler CLI; see [setup and prerequisites](plugins/asyncswap-filler/README.md).

```
/plugin install asyncswap-filler@asyncswap
```

### Unichain bundles

Prepare bounded, revert-protected Unichain bundle requests for transfers, swaps, and other specified transactions. Independent of Async Swap filler orders. Includes eth-libs request-building guidance; no signer or submission service. See [the skill and reference](plugins/unichain-bundles/README.md).

```
/plugin install unichain-bundles@asyncswap
```

### Ethereum bundles

Prepare Ethereum mainnet Flashbots and MEV-Share bundles using eth-libs, with
simulation and relay authentication guidance. Separate from Unichain bundles.
See [setup and scope](plugins/ethereum-bundles/README.md).

```
/plugin install ethereum-bundles@asyncswap
```

## License

MIT
