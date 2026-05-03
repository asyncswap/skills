---
name: callHierarchy/incomingCalls
description: YAML for `callHierarchy/incomingCalls`. Cursor on a function name; harness chains `prepareCallHierarchy → incomingCalls`.
---

# bench `callHierarchy/incomingCalls`

```yaml
methods:
  callHierarchy/incomingCalls:
    waitForProgressToken: "solidity/projectIndexFull"
    expect: { minCount: 1 }
```

Cursor on the function name (declaration or call site). `prepareCallHierarchy` must succeed first — fix the cursor if it returns null. Cross-contract resolution requires the full project index.
