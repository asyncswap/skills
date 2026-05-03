---
name: lifecycle-tests
description: Test full file-rename / create / delete lifecycles via `renameFiles:`, `createFiles:`, and `deleteFiles:`. Each step exercises the LSP's request → apply edits → on-disk operation → notification → re-index cycle and restores the project at the end.
---

# Lifecycle tests

`workspace/will{Rename,Create,Delete}Files` doesn't just compute a `WorkspaceEdit` — the editor *actually applies* the edits, performs the file op, and notifies via `did{Rename,Create,Delete}Files`. The harness reproduces this end-to-end so cross-file effects (import updates, cache invalidations) are exercised, then restores the project.

## File rename — `renameFiles:`

```yaml
initializeSettings:
  fileOperations:
    updateImportsOnRename: true

methods:
  workspace/willRenameFiles:
    waitForProgressToken: "<token>"
    renameFiles:
      - { file: A.sol,  newName: AA.sol, expect: { count: 1 } }
      - { file: AA.sol, newName: A.sol,  expect: { count: 1 } }
      - { file: A.sol,  newName: AA.sol, expect: { count: 1 } }
      - { file: AA.sol, newName: A.sol,  expect: { count: 1 } }
```

Each step runs: `willRenameFiles` → apply returned edits to disk → `mv oldUri newUri` → `didRenameFiles` → `didChange` on every edited file → wait for re-index. After all steps the harness restores files to original state.

`expect.count` = number of *files* with edits (not number of edits within them).

Round-trips (`A → AA → A → AA → A`) catch idempotency bugs in the import-update logic.

## File creation — `createFiles:`

```yaml
initializeSettings:
  fileOperations:
    templateOnCreate: true

methods:
  workspace/willCreateFiles:
    createFiles:
      - file: src/NewContract.sol
        expect: { count: 1 }
```

Each step runs: `willCreateFiles` → apply scaffold edits → create the file on disk → `didCreateFiles`. Created files are deleted at the end.

## File deletion — `deleteFiles:`

```yaml
initializeSettings:
  fileOperations:
    updateImportsOnDelete: true

methods:
  workspace/willDeleteFiles:
    waitForProgressToken: "<token>"
    deleteFiles:
      - file: src/ToBeDeleted.sol
        expect: { count: 1 }
```

Each step runs: `willDeleteFiles` → apply import-cleanup edits in dependents → delete the file → `didDeleteFiles` → wait for re-index. The harness restores deleted files from a snapshot.

## Required `initializeSettings`

Most servers gate file-operation logic on settings. Without these flags the LSP returns empty `WorkspaceEdit`s:

| Lifecycle | Setting |
|---|---|
| Rename | `fileOperations.updateImportsOnRename: true` |
| Create | `fileOperations.templateOnCreate: true` |
| Delete | `fileOperations.updateImportsOnDelete: true` |

## Common pitfalls

- The target file must exist on disk at step start (rename/delete) and *not* exist (create). The harness restores between runs, but if a previous run crashed mid-flight, manually clean up before running again.
- Round-trip renames (`A → AA → A`) are the right shape for catching state bugs — single renames don't exercise the "rename back" path.
- `waitForProgressToken` is required when the server reindexes asynchronously after the file op. Without it, the next step's request sees stale state.
