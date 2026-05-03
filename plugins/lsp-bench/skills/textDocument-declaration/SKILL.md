---
name: textDocument/declaration
description: YAML for `textDocument/declaration`. For Solidity, typically equivalent to `definition` — use to assert both methods agree.
---

# bench `textDocument/declaration`

```yaml
methods:
  textDocument/declaration:
    waitForProgressToken: "solidity/projectIndexFull"
    expect: { file: target.sol, line: 41 }
```

Cursor on a usage site. For Solidity, response should match `textDocument/definition` for the same cursor — divergence is a bug worth filing.
