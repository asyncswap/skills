---
name: textDocument/completion
description: YAML for `textDocument/completion`. Use `trigger` for `.` member access; `containsItems` to assert specific labels appear. `didChange:` exercises the same trigger across an evolving file.
---

# bench `textDocument/completion`

```yaml
methods:
  textDocument/completion:
    line: 135
    col:  37          # position immediately AFTER the trigger character
    trigger: "."
    expect:
      containsItems:
        - label: addTax
        - label: getRefund
```

Cursor must be **after** the trigger character, not on it. Off-by-one on `col` is the most common mistake.

## Across edited snapshots (`didChange:`)

Track completion items at the same trigger site as the file evolves — positions shift but the expected items shouldn't change unless the edit altered the type's surface.

```yaml
methods:
  textDocument/completion:
    line: 160
    col:  18
    trigger: "."
    # order. — member completion on Order struct (buyer, nonce, amount, …)
    didChange:
      - file: Shop.v2.snapshot
        line: 162
        col:  18
        # order. shifted (getPrice added above)
      - file: Shop.v3.snapshot
        line: 160
        col:  18
        # order. shifted +1 (new event/error above)
      - file: Shop.v4.snapshot
        line: 166
        col:  18
        # order. shifted (both edits)
```
