---
name: textDocument/prepareCallHierarchy
description: YAML for `textDocument/prepareCallHierarchy`. Resolves the cursor to a `CallHierarchyItem` — precondition for incoming/outgoingCalls.
---

# bench `textDocument/prepareCallHierarchy`

```yaml
methods:
  textDocument/prepareCallHierarchy:
    waitForProgressToken: "solidity/projectIndexFull"
    expect: { minCount: 1 }
```

Cursor on a function name (declaration or call site). The harness chains `prepareCallHierarchy → incomingCalls/outgoingCalls` automatically when those methods are benched.
