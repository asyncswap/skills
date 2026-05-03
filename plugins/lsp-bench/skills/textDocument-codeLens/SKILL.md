---
name: textDocument/codeLens
description: YAML for `textDocument/codeLens`. Inline annotations above declarations (run-test, references-count). Often unimplemented for Solidity LSPs.
---

# bench `textDocument/codeLens`

```yaml
methods:
  textDocument/codeLens:
    expect: { minCount: 1 }
```

Whole-doc. Many Solidity LSPs return null — add to top-level `exclude:` if so.
