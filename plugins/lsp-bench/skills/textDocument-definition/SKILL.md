---
name: textDocument/definition
description: YAML for `textDocument/definition`. Use for goto-definition speed and validating cross-file resolution.
---

# bench `textDocument/definition`

```yaml
methods:
  textDocument/definition:
    waitForProgressToken: "solidity/projectIndexFull"
    expect: { file: target.sol, line: 41 }
```

Cursor on a usage site. For qualified paths (`IFoo.Bar`), put it on the segment whose def you want. `waitForProgressToken` is required when def lives in a different compile unit.
