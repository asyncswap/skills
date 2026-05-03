---
name: textDocument/semanticTokens/range
description: YAML for `textDocument/semanticTokens/range`. Range-based highlighting; faster than `/full` for editor viewport rendering.
---

# bench `textDocument/semanticTokens/range`

```yaml
methods:
  textDocument/semanticTokens/range:
    startLine: 0
    startCol:  0
    line: 100      # endLine
    col:  0        # endCol
```

Range crossing only comments yields zero tokens — pick a representative ~50-line viewport.
