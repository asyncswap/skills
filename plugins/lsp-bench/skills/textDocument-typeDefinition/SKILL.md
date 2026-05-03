---
name: textDocument/typeDefinition
description: YAML for `textDocument/typeDefinition`. Use to validate that variables/expressions resolve to their declared type.
---

# bench `textDocument/typeDefinition`

```yaml
methods:
  textDocument/typeDefinition:
    waitForProgressToken: "solidity/projectIndexFull"
    expect: { minCount: 1 }
```

Cursor on a variable, parameter, or expression — not on the type name. Primitives (`uint256`, `address`) typically yield empty; test against user-defined types (structs, contracts, enums).
