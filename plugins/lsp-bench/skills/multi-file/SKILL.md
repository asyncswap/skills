---
name: multi-file
description: Run the same LSP method against multiple `(file, line, col)` triples in one bench session via `batch:`. Use to perf-sweep across files, or to check references from different files / locations all return the same set.
---

# Multi-file probes with `batch:`

`batch:` runs the same method N times — once per entry — each at the entry's own file/line/col. The bench `didOpen`s each file (idempotent), waits for diagnostics, and sends the request. All N responses are captured in `results.json`.

## Simple — perf sweep across files

```yaml
methods:
  textDocument/references:
    batch:
      - { file: src/Foo.sol,     line: 22,  col: 8  }
      - { file: src/Bar.sol,     line: 100, col: 14 }
      - { file: tests/Baz.t.sol, line: 50,  col: 9  }
```

Each step gets its own timing entry — useful to catch "method is fast on one file but slow on another".

## Check references from different files match

When all N cursors point at the same symbol — the definition and several usages — every response should return the same set. The bench compares them and prints:

- `ok responses consistent — all N cursors (across files / locations) returned the same reference set`
- `warn responses inconsistent across cursors — different files / locations returned different reference sets` with a per-step `+extras −drops` diff

```yaml
methods:
  textDocument/references:
    waitForProgressToken: "<token>"
    batch:
      - { file: src/IFoo.sol,    line: 22,  col: 8  }   # event def
      - { file: tests/Foo.t.sol, line: 55,  col: 18 }   # emit usage
      - { file: tests/Bar.t.sol, line: 266, col: 36 }   # .selector access
```

Catches the bug class where querying from the definition returns a smaller set than querying from a usage (or vice versa) — a real LSP error if they should be the same.

## Per-step `expect:`

Each entry takes its own `expect:` (see the `assert-results` skill). With `--verify`, per-step assertions run alongside the consistency check.

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

- Without `waitForProgressToken`, the first step may run before background indexing has covered all the files later steps probe — the bench will report inconsistent responses for what's actually a timing race. Always pair `batch:` with the appropriate token wait when running cross-file methods.
- All cursor positions must point at the *same* symbol for the consistency check to be meaningful. If you're sweeping diverse sites for perf, ignore the warning.
