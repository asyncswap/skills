---
name: textDocument/rename
description: YAML for `textDocument/rename`. Computes the project-wide WorkspaceEdit; does **not** apply to disk (use `workspace/willRenameFiles` for the full lifecycle). Use `didChange` to bench rename across an evolving sequence of file snapshots.
---

# bench `textDocument/rename`

```yaml
methods:
  textDocument/rename:
    waitForProgressToken: "solidity/projectIndexFull"
    newName: "renamedSymbol"
```

Cursor on the symbol. Pick a `newName` that doesn't collide with existing symbols. Cross-file edits need the full project index — `waitForProgressToken` is required.

## Across edited snapshots (`didChange:`)

Each step sends a snapshot via `didChange` then re-runs rename at the snapshot's position. Useful for tracking how rename scope changes as the file evolves (added callers, new modifier usages, etc.).

```yaml
methods:
  textDocument/rename:
    line: 70
    col:  27
    # owner — 14+ occurrences across contract
    didChange:
      - file: Shop.v2.snapshot
        line: 69
        col:  27
        # owner — same count (getPrice doesn't reference owner)
      - file: Shop.v3.snapshot
        line: 69
        col:  27
        # owner — cancelOrder uses onlyOwner, may add to rename scope
      - file: Shop.v4.snapshot
        line: 69
        col:  27
        # owner — both edits applied
```

Iteration 0 is the baseline at the top-level `line`/`col`; each `didChange` entry produces one further iteration with that snapshot's content + position. Place comments next to each step describing the expected delta to make regressions in rename scope easy to spot.
