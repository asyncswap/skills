---
name: textDocument/documentHighlight
description: YAML for `textDocument/documentHighlight`. Highlights all in-file occurrences of the identifier under the cursor (intra-file only).
---

# bench `textDocument/documentHighlight`

```yaml
methods:
  textDocument/documentHighlight:
    expect: { minCount: 2 }      # decl + ≥1 usage
```

Cursor on any identifier. Intra-file only — not a project-wide refs replacement. No `waitForProgressToken` needed.
