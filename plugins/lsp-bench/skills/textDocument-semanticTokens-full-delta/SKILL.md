---
name: textDocument/semanticTokens/full/delta
description: YAML for `textDocument/semanticTokens/full/delta`. Incremental update relative to a prior `/full` baseline — cheapest variant once seeded.
---

# bench `textDocument/semanticTokens/full/delta`

```yaml
methods:
  textDocument/semanticTokens/full/delta: {}
```

Requires a prior `/full` request to seed; the harness chains automatically. Some servers fall back to `/full` on stale state — timing then doesn't reflect a true delta.
