---
name: textDocument/hover
description: YAML for `textDocument/hover`. Use for hover latency and validating NatSpec / `@inheritdoc` / function selectors.
---

# bench `textDocument/hover`

```yaml
methods:
  textDocument/hover:
    expect: { contains: "function transfer" }
```

Cursor on any identifier. For events/errors, hover renders the selector. No `waitForProgressToken` needed unless hovering on a cross-file inherited member.
