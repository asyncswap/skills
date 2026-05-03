---
name: textDocument/semanticTokens/full
description: YAML for `textDocument/semanticTokens/full`. Full-document semantic highlighting tokens.
---

# bench `textDocument/semanticTokens/full`

```yaml
methods:
  textDocument/semanticTokens/full:
    expect: { minCount: 1 }
```

Whole-doc, slowest of the three semanticTokens variants. Pair with `/range` (viewport) and `/full/delta` (incremental) for a complete picture.
