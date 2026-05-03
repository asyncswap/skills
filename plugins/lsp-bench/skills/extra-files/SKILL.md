---
name: extra-files
description: Open additional files mid-session via `didOpen:` and re-run the request on the original file. Use to test cross-file discovery — does the response grow as the LSP learns about more files?
---

# Open extra files mid-session — `didOpen:`

`didOpen:` opens additional files between iterations. The bench primary file is opened first; each `didOpen` step opens its file via `textDocument/didOpen`, waits for diagnostics, then re-sends the request **on the original primary file**.

## Simple

```yaml
file: src/Caller.sol
line: 22
col:  8

methods:
  textDocument/references:
    didOpen:
      - file: src/Importer1.sol
      - file: src/Importer2.sol
      - file: tests/Foo.t.sol
```

Iteration timeline:

1. Open `src/Caller.sol` → request → record response (baseline)
2. Open `src/Importer1.sol` → wait for diagnostics → request on `src/Caller.sol` → record
3. Open `src/Importer2.sol` → … → record
4. Open `tests/Foo.t.sol` → … → record

Each step adds one iteration; the response should grow as the LSP discovers more cross-file usages (or stay stable if the new file doesn't reference the symbol).

## Per-step `expect:`

```yaml
methods:
  textDocument/references:
    expect: { minCount: 2 }                   # baseline (def + same-file usage)
    didOpen:
      - file: src/Importer1.sol
        expect: { minCount: 5 }               # adds 3 usages
      - file: src/Importer2.sol
        expect: { minCount: 8 }
```

## Compared to `batch:`

| Knob | Cursor target | Use case |
|---|---|---|
| `didOpen:` | original `file` (request stays on the same cursor) | "does refs grow as I learn about more files?" |
| `batch:` | each step's own `file/line/col` | "does each cursor return the same set?" |

## Common pitfalls

- Opening a file via `didOpen` triggers a per-file build asynchronously. The bench's diagnostics-wait may return on the LSP's empty "clearing" publish *before* the real compile finishes — if the next request returns identical results to the previous one, your real compile may not have landed yet. Pair with a longer `index_timeout` or pin to a method that doesn't depend on cross-file state for verification.
- `didOpen:` re-sends the same request on the same primary file. If you want to *change* the cursor target between steps, use `batch:` instead.
