---
name: textDocument/inlayHint
description: YAML for `textDocument/inlayHint`. Range-based — `startLine`/`startCol` set the start; `line`/`col` the end.
---

# bench `textDocument/inlayHint`

```yaml
initializeSettings:
  inlayHints:
    parameters: true

methods:
  textDocument/inlayHint:
    startLine: 130
    startCol:  0
    line: 147       # endLine
    col:  0         # endCol
    expect: { minCount: 1 }
```

`initializeSettings.inlayHints` must enable hints. Whole-file: `startLine: 0, startCol: 0, line: <total>, col: 0`.
