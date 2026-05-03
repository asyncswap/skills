---
name: workspace/willDeleteFiles
description: YAML for `workspace/willDeleteFiles`. `deleteSteps` runs willDelete → apply import-cleanup edits → delete on disk → didDelete → wait for re-index, restored at the end.
---

# bench `workspace/willDeleteFiles`

```yaml
initializeSettings:
  fileOperations:
    updateImportsOnDelete: true

methods:
  workspace/willDeleteFiles:
    waitForProgressToken: "solidity/projectIndexFull"
    deleteSteps:
      - file: src/ToBeDeleted.sol
        expect: { count: 1 }       # dependents needing import cleanup
```

Pick a file with at least one dependent so `count` is non-zero. `updateImportsOnDelete` must be enabled.
