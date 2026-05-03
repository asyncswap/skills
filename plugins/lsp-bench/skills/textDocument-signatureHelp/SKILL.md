---
name: textDocument/signatureHelp
description: YAML for `textDocument/signatureHelp`. Cursor must be inside the call's parens.
---

# bench `textDocument/signatureHelp`

```yaml
methods:
  textDocument/signatureHelp: {}
```

Cursor inside `func(|here)`. Position after a comma to test active-parameter advancement: `func(arg1, |arg2)` → param index 1.
