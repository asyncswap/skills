---
name: workspace/willRenameFiles
description: YAML for `workspace/willRenameFiles`. `renameSteps` runs the full lifecycle — willRename → apply edits → rename on disk → didRename → wait for re-index, restored at the end.
---

# bench `workspace/willRenameFiles`

```yaml
initializeSettings:
  fileOperations:
    updateImportsOnRename: true

methods:
  workspace/willRenameFiles:
    waitForProgressToken: "solidity/projectIndexFull"
    renameSteps:
      - { file: A.sol,  newName: AA.sol, expect: { count: 1 } }
      - { file: AA.sol, newName: A.sol,  expect: { count: 1 } }
```

`expect.count` = number of *files* with edits (not edits within them). `updateImportsOnRename` must be enabled or the response is empty.
