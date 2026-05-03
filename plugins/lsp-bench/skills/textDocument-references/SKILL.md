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

Skipping `waitForProgressToken` races phase 2 → partial results that look like a bug.
