---
name: custom-init-settings
description: Send custom configuration to the LSP during `initialize` via `initializeSettings:`. Mirrors the editor's settings block — used to enable inlay hints, lint, file-operations, custom indexing modes, etc.
---

# Custom settings via `initializeSettings:`

Top-level `initializeSettings:` is forwarded as `initializationOptions` in the LSP `initialize` request. Whatever the server documents as its editor settings goes here verbatim.

## Simple

```yaml
initializeSettings:
  inlayHints:
    parameters: true
```

## A typical Solidity LSP block

```yaml
initializeSettings:
  projectIndex:
    fullProjectScan: true              # required for cross-file refs/definition
    cacheMode: "v2"                    # on-disk cache schema
    incrementalEditReindex: false

  inlayHints:
    parameters: true
    gasEstimates: true

  lint:
    enabled: true
    severity: []
    only: []
    exclude: []

  fileOperations:
    templateOnCreate: true             # enables willCreateFiles scaffolding
    updateImportsOnRename: true        # enables willRenameFiles edits
    updateImportsOnDelete: true        # enables willDeleteFiles edits
```

Pick only the subset relevant to your bench — most servers ignore unknown keys.

## When each block matters

| Setting | Required for |
|---|---|
| `projectIndex.fullProjectScan: true` | cross-file `references`, `definition`, `implementation`, `callHierarchy/*` |
| `inlayHints.parameters: true` | non-empty `textDocument/inlayHint` response |
| `lint.enabled: true` | lint diagnostics → most `textDocument/codeAction` quickfixes |
| `fileOperations.templateOnCreate: true` | `workspace/willCreateFiles` scaffold edits |
| `fileOperations.updateImportsOnRename: true` | `workspace/willRenameFiles` import edits |
| `fileOperations.updateImportsOnDelete: true` | `workspace/willDeleteFiles` import cleanup |

If your method's response is unexpectedly empty/null, check whether the corresponding `initializeSettings` flag is set — the LSP may be quietly disabling that feature.

## Sharing across configs

Pull the `initializeSettings:` block into a `shared.yaml` and `include:` it from every config — see the `setup` skill.

## Common pitfalls

- The settings shape is server-defined. Check the server's docs for the exact key names (`projectIndex` vs `project_index` vs `projectIndexing`).
- A typo in a key is silent — most servers ignore unknown keys without warning. If a feature won't activate, log the LSP `initialize` request payload and confirm the keys match docs.
