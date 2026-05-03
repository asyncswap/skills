---
name: setup
description: Project layout, `servers.yaml` registry, and top-level config keys for `lsp-bench`. Use before writing per-method configs to set up shared bits (registry, common `initializeSettings`, `include:` composition); reference when the user asks "where do I configure servers" or "how do I bench against multiple versions".
---

# `lsp-bench` setup

`lsp-bench` reads two YAMLs: a **server registry** (once per project) and **bench configs** (one per scenario). Per-method skills cover the bench config; this skill covers the cross-cutting setup.

## Top-level keys

| Key                 | Default          | Notes |
|---------------------|------------------|-------|
| `project`           | `"."`            | Project root with `foundry.toml` etc. The bench `cd`s here. |
| `file`              | `""`             | File to `didOpen` first, relative to `project`. |
| `line` / `col`      | `102` / `15`     | 0-indexed cursor (LSP convention). Editor 1-indexed → subtract 1. |
| `iterations`        | `10`             | Measured iterations. |
| `warmup`            | `2`              | Discarded warmup iterations. |
| `timeout`           | `10` (s)         | Per-request. Bump for `rename` / `willRenameFiles`. |
| `index_timeout`     | `15` (s)         | Diagnostics / progress wait. Bump to `60`–`300` for large projects. |
| `output`            | `"benchmarks"`   | Where `results.json` lands. |
| `report`            | `null`           | Markdown report path; omit to skip. |
| `benchmarks`        | `[]` = run all   | LSP methods to bench. Empty or `["all"]` runs every supported method. |
| `exclude`           | `[]`             | Filter applied **after** `benchmarks` resolves. |
| `methods`           | `{}`             | Per-method overrides (`line`, `col`, `expect`, `trigger`, `cold`, `batch`, `didOpen`, `renameSteps`, …). Only applied if the method is in the active list. |
| `servers`           | `["mmsaki"]`     | Registry refs (`mmsaki`, `mmsaki@v0.1.20`) or inline `{ label, cmd, args }`. Multiple = side-by-side. |
| `servers_file`      | auto-discovered  | Path to `servers.yaml`. Defaults: next to the config or under `benchmarks/`. |
| `include`           | `[]`             | Sub-configs whose settings merge as defaults; this config wins on conflicts. Paths resolve relative to the including file. |
| `initializeSettings`| `null`           | Object forwarded as `initializationOptions` in `initialize`. Mirrors the editor's settings block. |
| `response_limit`    | `80`             | Bytes of each response embedded in `results.json`. |

### `benchmarks` × `exclude` × `methods`

Active method list = `benchmarks` (or all methods if empty/`"all"`) **minus** `exclude`. `methods.<key>` only applies if `<key>` is active.

```yaml
# Run everything except three methods, with per-method tuning.
exclude:
  - textDocument/typeDefinition
  - textDocument/codeLens

methods:
  textDocument/references:
    waitForProgressToken: "solidity/projectIndexFull"
    expect: { minCount: 2 }
  textDocument/completion:
    trigger: "."
    expect: { containsItems: [ { label: addTax } ] }
```

Pin a subset for CI / iteration:

```yaml
benchmarks:
  - textDocument/references
  - textDocument/definition
  - callHierarchy/incomingCalls
```

## Project layout

```
<project root>/
├── foundry.toml
├── benchmarks/
│   ├── servers.yaml          # registry — auto-discovered
│   ├── shared.yaml           # common preamble (optional)
│   ├── refs.yaml             # one bench config per scenario
│   ├── hover.yaml
│   └── ...
```

Override registry path: `lsp-bench -c benchmarks/refs.yaml -s benchmarks/servers.yaml -v`

## `servers.yaml`

Define each LSP server once; reference by name in any config. Versions live under `versions:` and are reachable via `name@version`.

```yaml
mmsaki:
  cmd: solidity-language-server          # default cmd (no @version)
  link: https://github.com/asyncswap/solidity-language-server
  versions:
    v0.1.20:
      cmd: /Users/meek/.solidity-lsp/0.1.20/bin/solidity-language-server
    latest:
      cmd: /abs/path/target/release/solidity-language-server

solc:
  cmd: solc
  args: ["--lsp"]

nomicfoundation:
  cmd: nomicfoundation-solidity-language-server
  args: ["--stdio"]
```

Fields: `cmd` (required), `args`, `link`, `versions`. Versions inherit anything missing from the parent. `latest` is a convention — typically points at your local build.

A/B regression — list multiple, run side-by-side automatically:

```yaml
servers:
  - mmsaki@v0.1.30
  - mmsaki@v0.1.32
  - mmsaki@latest
```

## `include:` composition

Pull recurring settings into a base file; reference from per-scenario configs.

```yaml
# benchmarks/shared.yaml
project: /abs/path/to/project
iterations: 10
warmup: 2
timeout: 10
index_timeout: 60
servers: [mmsaki@latest]
initializeSettings:
  projectIndex: { fullProjectScan: true }
  inlayHints:   { parameters: true, gasEstimates: true }
  lint:         { enabled: true }
  fileOperations:
    templateOnCreate: true
    updateImportsOnRename: true
    updateImportsOnDelete: true
```

```yaml
# benchmarks/refs.yaml
include: [shared.yaml]

file: src/Target.sol
line: 22
col:  8
output: benchmarks/refs

benchmarks:
  - textDocument/references

methods:
  textDocument/references:
    waitForProgressToken: "solidity/projectIndexFull"
    expect: { minCount: 1 }
```

Per-scenario keys win over included defaults. Paths in `include:` resolve relative to the including file, not the cwd of `lsp-bench`.

## Pitfalls

- **Don't repurpose `latest` mid-flight.** Pin specific versions in regression configs so the captured run is reproducible.
- **`include:` paths** are file-relative, not cwd-relative.
- **`servers:` shadowing**: per-config `servers:` shadows the include. To override for one scenario, just declare a new block.
- **`projectIndex.fullProjectScan: true`** is required for cross-file methods (refs, definition, implementation, call hierarchy). Without it those return only what the per-file build sees.
