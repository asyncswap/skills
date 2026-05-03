---
name: textDocument/prepareRename
description: YAML for `textDocument/prepareRename`. Cheap precheck — returns the renameable range or null.
---

# bench `textDocument/prepareRename`

```yaml
methods:
  textDocument/prepareRename:
    expect: { line: 135 }
```

Cursor on an identifier. A null response on a non-renameable position (whitespace, keyword) is correct — assert with `expect: { shape: null }` if testing that.
