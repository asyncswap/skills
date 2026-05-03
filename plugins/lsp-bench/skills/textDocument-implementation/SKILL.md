---
name: textDocument/implementation
description: YAML for `textDocument/implementation`. Use for interface→impl resolution and validating multi-impl discovery.
---

# bench `textDocument/implementation`

```yaml
methods:
  textDocument/implementation:
    waitForProgressToken: "solidity/projectIndexFull"
    expect: { minCount: 1 }
```

Cursor on the interface/abstract function name (the declaration). Implementation discovery scans the project — `waitForProgressToken` is required.
