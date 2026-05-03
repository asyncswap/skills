---
name: callHierarchy/outgoingCalls
description: YAML for `callHierarchy/outgoingCalls`. Cursor on a function name; harness chains `prepareCallHierarchy → outgoingCalls`.
---

# bench `callHierarchy/outgoingCalls`

```yaml
methods:
  callHierarchy/outgoingCalls:
    waitForProgressToken: "solidity/projectIndexFull"
    expect: { minCount: 1 }
```

Cursor on the function name.
