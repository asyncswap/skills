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

## License

MIT
