---
name: textDocument/foldingRange
description: YAML for `textDocument/foldingRange`. Whole-file foldable regions (contracts, functions, blocks, comments, imports).
---

# bench `textDocument/foldingRange`

```yaml
methods:
  textDocument/foldingRange:
    expect: { minCount: 5 }
```

Whole-doc — `line`/`col` unused. Pick a representative file with at least one contract + function for a meaningful baseline.
