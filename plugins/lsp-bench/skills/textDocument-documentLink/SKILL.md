---
name: textDocument/documentLink
description: YAML for `textDocument/documentLink`. Clickable links (imports, type names) within the document.
---

# bench `textDocument/documentLink`

```yaml
methods:
  textDocument/documentLink:
    expect: { minCount: 1 }
```

Whole-doc. Files with no imports/links yield empty.
