---
name: methods
description: Per-method config schema for every LSP method `lsp-bench` supports. Lists every key valid under each `methods.<method>:` block — required, optional, type, default. Use to validate what a method's config can or cannot do.
---

# Method config schema reference

Every key valid under a `methods.<method>:` block, per LSP method. Cross-cutting keys (work on every method) are listed once; method-specific keys are called out per method.

## Conventions

- `?` after a key name = optional
- Top-level `line` / `col` are the **default cursor for every method**. Each method block can override.
- `expect:` shape varies per method (see `assert-results` skill for full shape).
- Sub-types (`BatchStep`, `FileSnapshot`, `DidOpenStep`, `RenameStep`, `CreateStep`, `DeleteStep`, `ExpectConfig`) are defined at the bottom.

## Cross-cutting keys

These are valid under **every** `methods.<method>:` block:

```yaml
# Cross-cutting MethodConfig keys
line:                  integer?                # override top-level cursor (line)
col:                   integer?                # override top-level cursor (col)
cold:                  boolean                 # default false — fresh server per iteration
waitForProgressToken:  string?                 # block until $/progress end matches this token
waitForProgress:       boolean                 # default false — wait for any $/progress end after the response
expect:                ExpectConfig?           # response shape assertions
batch:                 BatchStep[]             # default [] — multi-cursor probes (see `multi-file` skill)
didChange:             FileSnapshot[]          # default [] — snapshot sequence (see `evolve-the-file` skill)
didOpen:               DidOpenStep[]           # default [] — open extras mid-session (see `extra-files` skill)
```

## Position-based methods

Cursor on an identifier; whitespace fallback hits the smallest enclosing AST node.

Methods: `textDocument/references`, `textDocument/definition`, `textDocument/declaration`, `textDocument/implementation`, `textDocument/typeDefinition`, `textDocument/hover`, `textDocument/documentHighlight`, `textDocument/prepareRename`, `textDocument/prepareCallHierarchy`, `textDocument/selectionRange`.

```yaml
# Schema: methods.textDocument/<position-method>
# (only cross-cutting keys — no method-specific keys)
line?:                  integer
col?:                   integer
cold?:                  boolean
waitForProgressToken?:  string
expect?:                ExpectConfig
batch?:                 BatchStep[]
didChange?:             FileSnapshot[]
didOpen?:               DidOpenStep[]
```

Validation:
- `line`/`col` must point at the symbol identifier (not whitespace).
- `waitForProgressToken` recommended for cross-file methods (`references`, `definition`, `declaration`, `implementation`, `typeDefinition`, `prepareCallHierarchy`).
- `documentHighlight` is intra-file — `waitForProgressToken` not required.
- `prepareRename` may legally return `null`; assert with `expect: { shape: null }`.

## Trigger-character methods

### `textDocument/completion`

```yaml
# Schema: methods.textDocument/completion
trigger:                string?                # required when fired by a trigger char (e.g. ".")
line?:                  integer
col?:                   integer
expect?:                ExpectConfig           # `containsItems` is the typical assertion
cold?:                  boolean
didChange?:             FileSnapshot[]
batch?:                 BatchStep[]
didOpen?:               DidOpenStep[]
```

Validation:
- `col` must be **after** the trigger character, not on it.
- `trigger` value (string) must match the configured trigger character on the server (`.`, `(`, `,`, `[`, `:`, etc.).

### `textDocument/signatureHelp`

```yaml
# Schema: methods.textDocument/signatureHelp
line?:                  integer
col?:                   integer                # must be inside the call's parens
expect?:                ExpectConfig
cold?:                  boolean
didChange?:             FileSnapshot[]
```

## Rename

### `textDocument/rename`

```yaml
# Schema: methods.textDocument/rename
newName:                string                 # REQUIRED
line?:                  integer
col?:                   integer
waitForProgressToken?:  string                 # required for cross-file edits
expect?:                ExpectConfig           # `count` = number of files with edits
cold?:                  boolean
didChange?:             FileSnapshot[]
```

Validation: `newName` must not collide with an existing symbol.

## Range-based methods

`startLine` + `startCol` mark the start; the method's `line` + `col` mark the end.

### `textDocument/inlayHint`

```yaml
# Schema: methods.textDocument/inlayHint
startLine:              integer                # REQUIRED — range start (line, 0-indexed)
startCol:               integer                # REQUIRED — range start (col, 0-indexed)
line:                   integer                # REQUIRED — range end (line)
col:                    integer                # REQUIRED — range end (col)
expect?:                ExpectConfig
cold?:                  boolean
didChange?:             FileSnapshot[]
```

Requires `initializeSettings.inlayHints.parameters: true` (or similar server-specific gate) — otherwise the response is empty.

### `textDocument/semanticTokens/range`

```yaml
# Schema: methods.textDocument/semanticTokens/range
startLine:              integer                # REQUIRED
startCol:               integer                # REQUIRED
line:                   integer                # REQUIRED — range end
col:                    integer                # REQUIRED — range end
expect?:                ExpectConfig
cold?:                  boolean
```

## Whole-document methods

`line`/`col` are placeholders (any value works — operation covers the whole document).

Methods: `textDocument/formatting`, `textDocument/foldingRange`, `textDocument/documentLink`, `textDocument/documentSymbol`, `textDocument/codeLens`, `textDocument/diagnostic`, `textDocument/documentColor`, `textDocument/semanticTokens/full`, `textDocument/semanticTokens/full/delta`.

```yaml
# Schema: methods.textDocument/<whole-doc-method>
expect?:                ExpectConfig
cold?:                  boolean
didChange?:             FileSnapshot[]         # idiomatic for `formatting` (send unformatted content)
```

Validation:
- `formatting` typically pairs with `didChange:` — sends an unformatted snapshot, asserts the formatter returns canonicalizing edits.
- `semanticTokens/full/delta` requires a prior `/full` to seed; the harness chains.
- `codeLens`, `documentColor`, `diagnostic` may return null on servers that don't implement them — add to top-level `exclude:` if so.

## Diagnostic-driven

### `textDocument/codeAction`

```yaml
# Schema: methods.textDocument/codeAction
line?:                  integer                # cursor on a position with an active diagnostic
col?:                   integer
expect?:                ExpectConfig           # `titleContains` is the typical assertion
cold?:                  boolean
didChange?:             FileSnapshot[]
```

Without an active diagnostic at the cursor, the response is empty. Most quickfix-emitting code requires `initializeSettings.lint.enabled: true`.

## Call hierarchy (chained)

Both `callHierarchy/incomingCalls` and `callHierarchy/outgoingCalls` chain from `prepareCallHierarchy`. Configure the cursor on the chained method; the harness chains automatically.

```yaml
# Schema: methods.callHierarchy/(incomingCalls | outgoingCalls)
line?:                  integer                # cursor on the function name
col?:                   integer
waitForProgressToken?:  string                 # required for cross-contract resolution
expect?:                ExpectConfig
cold?:                  boolean
batch?:                 BatchStep[]
```

Validation: if `prepareCallHierarchy` returns null at the cursor, the chained method errors. Fix the cursor.

## Workspace-scoped

### `workspace/symbol`

```yaml
# Schema: methods.workspace/symbol
waitForProgressToken?:  string                 # required for full coverage
expect?:                ExpectConfig
cold?:                  boolean
```

`file`/`line`/`col` are placeholders (search is project-wide). Default query is empty — returns all symbols.

### `workspace/executeCommand`

```yaml
# Schema: methods.workspace/executeCommand
command:                string                 # REQUIRED — server-defined command name
arguments:              any[]                  # default [] — forwarded as-is to the command handler
waitForProgress?:       boolean                # default false — block on $/progress end after response
expect?:                ExpectConfig           # `shape: null` matches commands that return null
cold?:                  boolean
```

Validation: `arguments` shape is server-specific; consult server docs.

### File-operation lifecycles

```yaml
# Schema: methods.workspace/willRenameFiles
renameSteps:            RenameStep[]           # REQUIRED, non-empty
waitForProgressToken?:  string                 # required when LSP reindexes async after rename
cold?:                  boolean

# Schema: methods.workspace/willCreateFiles
createSteps:            CreateStep[]           # REQUIRED, non-empty
cold?:                  boolean

# Schema: methods.workspace/willDeleteFiles
deleteSteps:            DeleteStep[]           # REQUIRED, non-empty
waitForProgressToken?:  string
cold?:                  boolean
```

Required `initializeSettings.fileOperations` flags:
- `updateImportsOnRename: true` for `willRenameFiles` to compute import edits
- `templateOnCreate: true` for `willCreateFiles` to scaffold
- `updateImportsOnDelete: true` for `willDeleteFiles` to clean up dependents

---

## Sub-type schemas

### `BatchStep`

```yaml
file:                   string                 # REQUIRED — relative to project root
line:                   integer                # REQUIRED — 0-indexed
col:                    integer                # REQUIRED — 0-indexed
expect?:                ExpectConfig
```

### `FileSnapshot`

Used in `didChange:`. Snapshot file holds the full edited content (not a diff).

```yaml
file:                   string                 # REQUIRED — snapshot filename
line:                   integer                # REQUIRED — cursor in this snapshot
col:                    integer                # REQUIRED
trigger?:               string                 # for completion: trigger char fired in this step
expect?:                ExpectConfig
```

### `DidOpenStep`

```yaml
file:                   string                 # REQUIRED — extra file to open mid-session
line?:                  integer                # rarely set — request stays on top-level cursor
col?:                   integer
expect?:                ExpectConfig           # response after this file is opened
```

### `RenameStep`

```yaml
file:                   string                 # REQUIRED — file to rename, relative to project
newName:                string                 # REQUIRED — new file name (or relative path)
expect?:                ExpectConfig           # `count` = number of files with edits
```

### `CreateStep`

```yaml
file:                   string                 # REQUIRED — path to create, relative to project
expect?:                ExpectConfig
```

### `DeleteStep`

```yaml
file:                   string                 # REQUIRED — path to delete, relative to project
expect?:                ExpectConfig
```

### `ExpectConfig`

Any subset of:

```yaml
minCount?:              integer                # response array has at least N entries
count?:                 integer                # response array has exactly N entries
file?:                  string                 # first response location's path ends with this
line?:                  integer                # first response location's line equals this
contains?:              string                 # response text/markdown includes this substring
containsItems?:         { label: string }[]    # completion result includes ALL these labels
titleContains?:         string                 # at least one CodeAction has a title containing this
shape?:                 "null" | "array" | "object"
```

Used by `--verify` mode (`lsp-bench --verify -c <config>`). Without `--verify`, `expect:` is recorded for the report but doesn't influence exit status.

---

## Method-key compatibility matrix

Quick lookup — which cross-cutting key applies to which method?

| Cross-cutting key (topic skill) | Position | Range / whole-doc | Workspace |
|---|---|---|---|
| `expect:` (`assert-results`) | ✅ all | ✅ all | ✅ all |
| `waitForProgressToken:` (`wait-for-token`) | ✅ when cross-file | ✅ rarely needed | ✅ for `symbol`, lifecycle |
| `waitForProgress:` (`wait-for-token`) | rarely | rarely | ✅ for `executeCommand` |
| `batch:` (`multi-file`) | ✅ idiomatic for refs/def/impl/highlight | rarely | rarely |
| `didChange:` (`evolve-the-file`) | ✅ all | ✅ all | rarely |
| `didOpen:` (`extra-files`) | ✅ when testing cross-file discovery growth | rarely | rarely |
| `cold:` (`cold-vs-warm`) | ✅ all | ✅ all | ✅ all |
| `initializeSettings:` (`custom-init-settings`) | ✅ when feature gated | ✅ same | ✅ for fileOperations |
| `renameSteps`/`createSteps`/`deleteSteps` (`lifecycle-tests`) | n/a | n/a | ✅ for `will*Files` |

## Method-specific keys at a glance

| Method | Specific key(s) | Required? |
|---|---|---|
| `textDocument/completion` | `trigger:` | when fired by trigger char |
| `textDocument/rename` | `newName:` | yes |
| `textDocument/inlayHint` | `startLine`/`startCol` (range start) | yes |
| `textDocument/semanticTokens/range` | `startLine`/`startCol` | yes |
| `workspace/executeCommand` | `command:`, `arguments:`, `waitForProgress:` | `command:` required |
| `workspace/willRenameFiles` | `renameSteps:` | yes |
| `workspace/willCreateFiles` | `createSteps:` | yes |
| `workspace/willDeleteFiles` | `deleteSteps:` | yes |
