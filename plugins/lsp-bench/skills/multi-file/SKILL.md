---
name: multi-file
description: Run the same LSP method against multiple `(file, line, col)` triples in one bench session via `batch:`. Use to perf-sweep across representative sites, or to check that responses are equivalent across cursors of the same logical symbol (symmetry).
---

# Multi-file probes with `batch:`

`batch:` runs the same method N times — once per entry — each at the entry's own file/line/col. The bench `didOpen`s each file (idempotent), waits for diagnostics, and sends the request. All N responses are captured in `results.json`.

## Simple — perf sweep across representative sites

```yaml
methods:
  textDocument/references:
    batch:
      - { file: src/Foo.sol,     line: 22,  col: 8  }
      - { file: src/Bar.sol,     line: 100, col: 14 }
      - { file: tests/Baz.t.sol, line: 50,  col: 9  }
```

Each step gets its own timing entry; useful to catch "method is fast on one file but slow on another".

## Symmetry assertion (free side-effect)

When all N cursors point at the same logical symbol, every response should match. The harness compares response sets pairwise and prints:

- `ok batch symmetry check passed — all N cursor positions return identical reference sets`
- `warn batch symmetry check failed — responses differ across cursor positions` with a per-step `+extras −drops` diff

```yaml
methods:
  textDocument/references:
    waitForProgressToken: "<token>"
    batch:
      - { file: src/IFoo.sol,    line: 22,  col: 8  }   # event def
      - { file: tests/Foo.t.sol, line: 55,  col: 18 }   # emit usage
      - { file: tests/Bar.t.sol, line: 266, col: 36 }   # .selector access
```

Symmetry is the right shape for `references` / `definition` / `implementation` / `documentHighlight` correctness — every site of a symbol must return the same set. A failing symmetry check is a real bug (or a timing race — make sure `waitForProgressToken` is set so background indexing has settled).

## Per-step `expect:`

Each entry takes its own `expect:` (see the `assert-results` skill).

```yaml
batch:
  - file: src/Foo.sol
    line: 22
    col:  8
    expect: { minCount: 16 }
  - file: tests/Foo.t.sol
    line: 55
    col:  18
    expect: { minCount: 16 }
```

## Common pitfalls

- Without `waitForProgressToken`, the first step may run before background indexing has covered all the files later steps probe — symmetry will appear to break. Always pair `batch:` with the appropriate token wait when running cross-file methods.
- All cursor positions must point at the *same* logical symbol for symmetry to be meaningful. If you're sweeping diverse sites for perf, ignore the symmetry warning.
