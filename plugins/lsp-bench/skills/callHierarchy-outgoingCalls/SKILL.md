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

Cursor on the function name. Pure/leaf functions return empty (correct). Low-level calls (`.call()`, `.delegatecall()`) typically don't show up — they're dynamic and resolver-opaque.
