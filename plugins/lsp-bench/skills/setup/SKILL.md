---
name: setup
description: Project layout, `servers.yaml` registry, and top-level config keys for `lsp-bench`. Use before writing per-method configs to set up shared bits (registry, common `initializeSettings`, `include:` composition); reference when the user asks "where do I configure servers" or "how do I bench against multiple versions".
---

# `lsp-bench` setup

`lsp-bench` reads two YAMLs: a **server registry** (once per project) and **bench configs** (one per scenario). Per-method skills cover the bench config; this skill covers the cross-cutting setup.

## Top-level config schema

Every key the parser accepts at the root of a bench config. `?` = optional. Defaults match the lsp-bench source.

```yaml
# Schema: Config (root)
project:            string                       # default "."        — project root, bench `cd`s here
file:               string                       # default ""         — required in practice; relative to `project`
line:               integer                      # default 102        — 0-indexed cursor; default for every method (overridable)
col:                integer                      # default 15         — 0-indexed cursor; default for every method (overridable)
iterations:         integer >= 0                 # default 10         — measured iterations
warmup:             integer >= 0                 # default 2          — discarded warmup iterations
timeout:            integer (seconds)            # default 10         — per-request timeout
index_timeout:      integer (seconds)            # default 15         — diagnostics / progress wait
output:             string (path)                # default "benchmarks"
report:             string?                      # default null       — markdown report path; omit to skip
benchmarks:         string[]                     # default []         — methods to run; [] or ["all"] = run every supported method
exclude:            string[]                     # default []         — methods to skip (filters `benchmarks` result)
methods:            map<string, MethodConfig>    # default {}         — per-method overrides; see `methods` skill
servers:            ServerRef[]                  # default ["mmsaki"] — registry refs OR inline {label, cmd, args}
servers_file:       string?                      # auto-discovered    — path to servers.yaml override
include:            string[]                     # default []         — sub-configs to merge as defaults (this config wins)
initializeSettings: object?                      # default null       — forwarded as initializationOptions
response_limit:     integer                      # default 80         — bytes of each response embedded in results.json
```

### `line` / `col` defaults vs per-method overrides

Top-level `line` and `col` define the **default cursor for every method**. Each `methods.<method>:` block can **override** them by setting its own `line`/`col`. If a method block omits them, it inherits from the top.

```yaml
file: src/Target.sol
line: 22       # default cursor — used by every method below unless overridden
col:  8

methods:
  textDocument/references: {}                # uses (22, 8)
  textDocument/hover:                        # uses (22, 8) — same cursor, different method
    expect: { contains: "@notice" }
  textDocument/definition:                   # OVERRIDE — different position
    line: 137
    col:  32
```

Step-shaped values (`batch:`, `didChange:`, `didOpen:`, `renameSteps:`, etc.) take their own `line`/`col` per step. The method's own `line`/`col` is the baseline iteration; each step is one further iteration.

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
