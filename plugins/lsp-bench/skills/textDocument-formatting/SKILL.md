---
name: textDocument/formatting
description: YAML for `textDocument/formatting`. Use `didChange` to send unformatted content first, then bench the formatter on it.
---

# bench `textDocument/formatting`

```yaml
methods:
  textDocument/formatting:
    didChange:
      - file: Target.unformatted.snapshot
        line: 0
        col:  0
```

`line`/`col` unused (whole-doc op). The snapshot file holds unformatted source the bench buffers in via `didChange`. For Solidity, `forge fmt` must be on `$PATH`.
