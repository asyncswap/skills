---
name: textDocument/definition
description: YAML for `textDocument/definition`. Use for goto-definition speed, validating cross-file resolution, or tracking def-resolution across an evolving file via `didChange:`.
---

# bench `textDocument/definition`

```yaml
methods:
  textDocument/definition:
    waitForProgressToken: "solidity/projectIndexFull"
    expect: { file: target.sol, line: 41 }
```

Cursor on a usage site. For qualified paths (`IFoo.Bar`), put it on the segment whose def you want. `waitForProgressToken` is required when def lives in a different compile unit.

## Across edited snapshots (`didChange:`)

Track def resolution as the file evolves — useful when an edit shifts positions or adds new code paths that could break resolution.

```yaml
methods:
  textDocument/definition:
    line: 137
    col:  32
    # PRICE — immutable declared at line 68
    didChange:
      - file: Shop.v2.snapshot
        line: 142
        col:  32
        # PRICE shifted (getPrice added above)
      - file: Shop.v3.snapshot
        line: 138
        col:  32
        # PRICE same offset (event/error added at bottom)
      - file: Shop.v4.snapshot
        line: 144
        col:  32
        # PRICE shifted (both edits combined)
```

Each step's `line`/`col` must point at the same logical symbol after the snapshot's edits — the bench reports an inconsistency if def resolves to a different location.
