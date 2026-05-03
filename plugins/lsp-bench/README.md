# lsp-bench

A Claude Code plugin that scaffolds, runs, and interprets [lsp-bench](https://github.com/asyncswap/lsp-bench) workflows for Solidity language servers — performance regression checks, correctness symmetry checks, request replay, and side-by-side version comparisons.

## Prerequisites

Install lsp-bench:

```sh
cargo install lsp-bench
# or build from source
git clone https://github.com/asyncswap/lsp-bench
cd lsp-bench && cargo install --path .
```

A `benchmarks/servers.yaml` registry is auto-discovered for resolving server names like `mmsaki@latest`.

## Installation

1. Add the marketplace:

```
/plugin marketplace add asyncswap/skills
```

2. Install the plugin:

```
/plugin install lsp-bench@asyncswap
```

## Skills

- **bench-init** — scaffold a `benchmark.yaml` for a target file/method, with reasonable defaults for cursor position, iterations, and timeouts
- **bench-symmetry** — multi-cursor correctness check using the `batch` config: every cursor on the same symbol must return the same response set (catches subset-bugs in `references`/`definition`/`implementation`)
- **bench-compare** — run a config against multiple LSP versions and produce a side-by-side diff of timings and response sets
- **bench-replay** — replay a captured JSON-RPC request from a benchmark output back at a server (great for debugging a specific failure)
- **bench-debug** — diagnose unexpected results from a recent benchmark run by inspecting the response, comparing to grep ground truth, and tracing the indexing-progress timeline

## License

MIT
