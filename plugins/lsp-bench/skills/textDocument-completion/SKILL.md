---
name: textDocument/completion
description: YAML for `textDocument/completion`. Use `trigger` for `.` member access; `containsItems` to assert specific labels appear.
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
