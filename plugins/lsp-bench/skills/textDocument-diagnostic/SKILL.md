---
name: textDocument/diagnostic
description: YAML for `textDocument/diagnostic`. Pull-based diagnostics; modern alternative to push `publishDiagnostics`.
---

# bench `textDocument/diagnostic`

```yaml
methods:
  textDocument/diagnostic:
    expect: { minCount: 1 }
```

Whole-doc. Some servers only support push diagnostics — null/error responses → add to `exclude:`.
