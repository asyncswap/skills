---
name: textDocument/references
description: YAML for `textDocument/references`. Use for ref enumeration speed, regression-testing cross-file refs, asserting `minCount`, or cross-cursor symmetry via `batch:`.
---

# bench `textDocument/references`

```yaml
methods:
  textDocument/references:
    waitForProgressToken: "solidity/projectIndexFull"
    expect: { minCount: 1 }
```

Cursor on a symbol identifier (def or usage). Whitespace fallbacks hit the enclosing contract — a misleading wide-reach result.

**Symmetry** (every site of the same symbol must return the same set):

```yaml
methods:
  textDocument/references:
    waitForProgressToken: "solidity/projectIndexFull"
    batch:
      - { file: src/IFoo.sol,    line: 22,  col: 8  }    # def
      - { file: tests/Foo.t.sol, line: 55,  col: 18 }    # emit
      - { file: tests/Bar.t.sol, line: 266, col: 36 }    # .selector
```

## Across edited snapshots (`didChange:`)

Track ref count as the file evolves — useful when an edit adds/removes usages and you want to confirm the LSP picks them up.

```yaml
methods:
  textDocument/references:
    line: 70
    col:  27
    # owner — 14+ usages across the contract
    didChange:
      - file: Shop.v2.snapshot
        line: 69
        col:  27
        # owner — same count (getPrice doesn't reference owner)
      - file: Shop.v3.snapshot
        line: 69
        col:  27
        # owner — cancelOrder uses onlyOwner (new indirect usage)
      - file: Shop.v4.snapshot
        line: 69
        col:  27
        # owner — both edits applied
```

Skipping `waitForProgressToken` races phase 2 → partial results that look like a bug.
