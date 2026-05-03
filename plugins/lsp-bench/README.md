# lsp-bench

Test, validate, and benchmark performance of LSP servers using only YAML. Helps you write [lsp-bench](https://github.com/asyncswap/lsp-bench) configs for:

- performance benchmarks (warm or cold-start)
- response assertions
- multi-file consistency checks
- benches across a sequence of file edits
- file-rename / create / delete lifecycle tests
- side-by-side LSP version comparisons

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

**Orientation**
- **setup** — project layout, `servers.yaml` registry, top-level config keys (`benchmarks`, `exclude`, `methods`, etc.), shared defaults via `include:`

**Method reference**
- **methods** — minimum-viable YAML for every LSP method `lsp-bench` supports, plus method-unique knobs (`trigger`, `newName`, range fields, `command`/`arguments`, …) and a knob-compatibility matrix

**Topic skills** (problem → solution)
- **wait-for-token** — wait for a specific LSP `$/progress` token before / after the request (`waitForProgressToken`, `waitForProgress`)
- **assert-results** — verify response shape with `expect:` (`minCount`, `containsItems`, `file`/`line`, `contains`, `titleContains`, `count`)
- **multi-file** — run the same method against multiple files / cursors with `batch:`; flags when the same method returns different sets from different places
- **evolve-the-file** — bench across a sequence of file edits using `didChange:` snapshots
- **extra-files** — open additional files mid-session via `didOpen:` and re-run on the original cursor
- **cold-vs-warm** — choose between cold-start (`cold: true`) and warm benches
- **lifecycle-tests** — full file-rename / create / delete lifecycle via `renameFiles`, `createFiles`, `deleteFiles`
- **custom-init-settings** — send custom configuration to the LSP via `initializeSettings:`
- **commands** — invoke server-defined commands via `workspace/executeCommand`

## License

MIT
