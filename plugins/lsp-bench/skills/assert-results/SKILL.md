---
name: assert-results
description: Verify the LSP response shape with `expect:`. Use when you want the bench to fail if the response shrinks, the wrong file resolves, or a specific completion item disappears.
---

# Assert results with `expect:`

Without `expect:`, the bench just records the response — it never fails on content. Add `expect:` to turn benches into regression tests.

## Common assertions

```yaml
methods:
  textDocument/references:
    expect: { minCount: 2 }              # at least N entries

  textDocument/definition:
    expect: { file: target.sol, line: 41 }   # response resolves to this location

  textDocument/hover:
    expect: { contains: "function transfer" }   # hover text includes this substring

  textDocument/completion:
    trigger: "."
    expect:
      containsItems:                      # at least these labels appear
        - label: addTax
        - label: getRefund

  textDocument/codeAction:
    expect: { titleContains: "Remove unused import" }   # at least one action with this title

  workspace/willRenameFiles:
    renameSteps:
      - file: A.sol
        newName: AA.sol
        expect: { count: 1 }              # number of *files* with edits
```

## Per-step assertions

When using `batch:`, `didChange:`, `didOpen:`, `renameSteps:`, `createSteps:`, or `deleteSteps:`, each step takes its own `expect:`. The top-level method `expect:` (if any) covers the baseline iteration; per-step `expect:` covers that step.

```yaml
methods:
  textDocument/references:
    expect: { minCount: 14 }                  # baseline
    didChange:
      - file: v2.snapshot
        expect: { minCount: 14 }              # same after edit
      - file: v3.snapshot
        expect: { minCount: 16 }              # +2 new usages
```

## Running with `--verify`

```sh
lsp-bench -c <config>.yaml --verify
```

Exits non-zero if any `expect:` fails. Without `--verify`, `expect:` is recorded for the report but doesn't influence the exit status.

## Common pitfalls

- `minCount` accepts looser-than-expected responses. Use `count` (exact) when you know the symbol's reference set is fixed.
- `expect: { file: X.sol }` matches any path ending in `X.sol`. Use a unique path segment if your project has files of the same name in different directories.
- For methods that may return null on a non-applicable position (e.g., `prepareRename` on whitespace), assert the null shape explicitly rather than `minCount: 0`.
