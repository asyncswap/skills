---
name: replay
description: Re-issue a captured LSP request from a previous benchmark run against any server. Use to debug a single failing request without re-running the full bench, or to bisect a regression by replaying the same request against earlier server versions.
---

# Replay an LSP request

Every bench run records the exact JSON-RPC payload it sent under each benchmark's `input` field in `results.json`. `lsp-bench replay` re-sends that payload against any server you point it at — same `initialize` + `didOpen` + the captured request, no YAML config needed.

Useful for:

- **Debugging one request in isolation.** A bench failed; you don't want to re-run setup + warmup + iterations to inspect that one response.
- **Bisecting regressions across versions.** Replay the same captured request against `v0.1.30`, `v0.1.31`, `latest` — find the first version where the response changed.
- **Reproducing a user's bug.** Ship them the `results.json` from their failing run; replay locally against your dev build.

## Usage

```sh
lsp-bench replay \
  --server "solidity-language-server --stdio" \
  --input '{"jsonrpc":"2.0","id":1,"method":"textDocument/references","params":{...}}' \
  --project /path/to/foundry/project
```

| Flag | Required? | Notes |
|---|---|---|
| `--server` / `-s` | yes | Server command. Quoted if it has args (`"solc --lsp"`). |
| `--input` / `-i` | yes | The JSON-RPC payload string. Copy from `results.json`'s `.benchmarks[N].input` field. |
| `--project` / `-p` | no | Project root (default: cwd). The bench `cd`s here before spawning the server. |
| `--file` / `-f` | no | File to `didOpen` first. Extracted from the input URI if omitted. |
| `--timeout` / `-t` | no | Response timeout in seconds (default: 30). |

## Recipe — pull the input from a results.json

```sh
INPUT=$(jq -r '.benchmarks[0].input' benchmarks/<name>/results.json)
lsp-bench replay -s "solidity-language-server --stdio" -i "$INPUT" -p $(pwd)
```

For a specific benchmark in a multi-method run, change the index (`.benchmarks[0]` → `.benchmarks[2]`).

## Recipe — bisect across versions

```sh
INPUT=$(jq -r '.benchmarks[0].input' results.json)
for v in v0.1.30 v0.1.31 v0.1.32 latest; do
  echo "=== $v ==="
  lsp-bench replay \
    -s "/Users/meek/.solidity-lsp/$v/bin/solidity-language-server --stdio" \
    -i "$INPUT" -p $(pwd)
done
```

The first version where the response shape changes is your regression entry point.

## Common pitfalls

- **The replayed `initialize` doesn't carry your bench config's `initializeSettings`.** If the captured request needed e.g. `projectIndex.fullProjectScan: true` to return correctly, replay won't reproduce the exact state. For settings-sensitive bugs, replay against a `lsp-bench -c <config>` run instead.
- **Replay does not run the iteration loop.** It sends the request once. Timing from replay is not comparable to the original bench's percentiles.
- **Cursor positions in `input` are 0-indexed LSP coords.** They're sent verbatim — same gotcha as the YAML configs.
- **Captured `input` is a literal JSON string.** Mind shell escaping when passing via `-i` (heredoc or `$(jq ...)` is safer than copy-paste).
