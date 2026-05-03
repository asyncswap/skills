---
name: textDocument/hover
description: YAML for `textDocument/hover`. Use for hover latency and validating NatSpec / `@inheritdoc` / function selectors. `didChange:` checks hover stability across file edits.
---

# bench `textDocument/hover`

```yaml
methods:
  textDocument/hover:
    expect: { contains: "function transfer" }
```

Cursor on any identifier. For events/errors, hover renders the selector. No `waitForProgressToken` needed unless hovering on a cross-file inherited member.

## Across edited snapshots (`didChange:`)

When the hovered symbol sits above any inserted edit, its position is stable — useful to confirm hover content (NatSpec, signature, selector) doesn't drift unexpectedly across versions of the file.

```yaml
methods:
  textDocument/hover:
    line: 42
    col:  13
    # addTax — function with @notice, @param, @return NatSpec
    didChange:
      - file: Shop.v2.snapshot
        line: 41
        col:  13
        # addTax — in Transaction library, above all edits
      - file: Shop.v3.snapshot
        line: 41
        col:  13
        # addTax — same position
      - file: Shop.v4.snapshot
        line: 41
        col:  13
        # addTax — same position
```
