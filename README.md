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

Helps you write [lsp-bench](https://github.com/asyncswap/lsp-bench) YAML configs — performance benchmarks, correctness checks (`batch:` symmetry), lifecycle tests, and version comparisons for any LSP server. Schema-style reference for every supported LSP method plus topic skills for cross-cutting features (`waitForProgressToken`, `expect:`, `didChange:`, `cold:`, etc.).

```
/plugin install lsp-bench@asyncswap
```

## License

MIT
