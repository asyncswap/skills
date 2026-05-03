---
name: textDocument/codeAction
description: YAML for `textDocument/codeAction`. Cursor on a position with an active diagnostic; `titleContains` asserts a specific quickfix.
---

# bench `textDocument/codeAction`

```yaml
initializeSettings:
  lint:
    enabled: true

methods:
  textDocument/codeAction:
    line: 263
    col:  8
    expect: { titleContains: "Remove unused import" }
```

Code actions attach to diagnostics — without one at the cursor, the response is empty. Lint-driven actions need `lint.enabled: true` in `initializeSettings`.
