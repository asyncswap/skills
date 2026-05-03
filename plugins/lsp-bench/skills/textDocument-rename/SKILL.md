---
name: textDocument/rename
description: YAML for `textDocument/rename`. Computes the project-wide WorkspaceEdit; does **not** apply to disk (use `workspace/willRenameFiles` for the full lifecycle).
---

# bench `textDocument/rename`

```yaml
methods:
  textDocument/rename:
    waitForProgressToken: "solidity/projectIndexFull"
    newName: "renamedSymbol"
```

Cursor on the symbol. Pick a `newName` that doesn't collide with existing symbols. Cross-file edits need the full project index — `waitForProgressToken` is required.
