---
name: workspace/willCreateFiles
description: YAML for `workspace/willCreateFiles`. `createSteps` scaffolds new files — willCreate → apply edits → create on disk → didCreate, deleted at the end.
---

# bench `workspace/willCreateFiles`

```yaml
initializeSettings:
  fileOperations:
    templateOnCreate: true

methods:
  workspace/willCreateFiles:
    createSteps:
      - file: src/NewContract.sol
        expect: { count: 1 }
```

`templateOnCreate` must be enabled to trigger scaffolding. Created path must not exist beforehand.
