---
name: methods
description: Per-method YAML reference for every LSP method `lsp-bench` supports. Each entry shows the minimum-viable form plus every optional knob the method accepts. Use to look up "what can I do with `textDocument/<X>`?". Cross-cutting features are documented in topic skills (`expect`, `batch`, `didChange`, `waitForProgressToken`, …).
---

# LSP method YAML reference

Each section gives the **minimum-viable YAML** plus a **fully-decked-out** example showing every knob applicable to that method. Pick what you need.

The bare shape is always:

```yaml
file: src/path/to/Target.sol
line: 0       # 0-indexed (LSP convention)
col:  0       # 0-indexed

methods:
  <lsp/method>: {}                   # minimum — request fires at top-level (line, col)
```

The method's own block can be empty. Add knobs as needed. Cross-cutting knobs (`expect`, `batch`, `didChange`, `waitForProgressToken`, etc.) work on **every** method below — see the corresponding topic skill for full semantics.

---

## Position-based (cursor on an identifier)

Applies to: `textDocument/references`, `textDocument/definition`, `textDocument/declaration`, `textDocument/implementation`, `textDocument/typeDefinition`, `textDocument/hover`, `textDocument/documentHighlight`, `textDocument/prepareRename`, `textDocument/prepareCallHierarchy`, `textDocument/selectionRange`.

Cursor on the symbol identifier. Whitespace fallback hits the smallest enclosing AST node and produces a misleading wide-reach response.

### Minimum

```yaml
methods:
  textDocument/references: {}
```

### Fully-decked-out

```yaml
methods:
  textDocument/references:
    line: 22                                  # optional: override top-level cursor
    col:  8                                   # optional
    cold: true                                # optional: fresh server per iteration
    waitForProgressToken: "<token>"           # optional: block until LSP token ends
    expect: { minCount: 1 }                   # optional: assert response shape
    batch:                                    # optional: multi-cursor probes
      - { file: src/Foo.sol,    line: 22,  col: 8  }
      - { file: tests/Foo.t.sol, line: 55,  col: 18 }
    didChange:                                # optional: re-bench across edits
      - file: Target.v2.snapshot
        line: 21
        col:  8
        expect: { minCount: 1 }
    didOpen:                                  # optional: open more files mid-session
      - file: src/Importer.sol
        expect: { minCount: 5 }
```

### Notes per method

- `references`, `definition`, `declaration`, `implementation`, `typeDefinition`, `prepareCallHierarchy` are **cross-file** — pair with `waitForProgressToken` so background indexing completes first.
- `hover`, `documentHighlight`, `prepareRename`, `selectionRange` are **file-local** — no project-wide wait needed (unless hovering an inherited member).
- `prepareRename` returning `null` on a non-renameable position is correct; assert with `expect: { shape: null }`.
- `documentHighlight` is intra-file only — not a `references` substitute.

---

## Trigger-character methods

### `textDocument/completion`

Method-unique knob: `trigger:` (informs the bench which trigger character fired). Cursor must be **after** the trigger character.

#### Minimum

```yaml
methods:
  textDocument/completion:
    trigger: "."
```

#### Fully-decked-out

```yaml
methods:
  textDocument/completion:
    line: 135
    col:  37                                  # immediately after the trigger char
    trigger: "."                              # required for trigger-char completion
    cold: true                                # optional
    expect:                                   # optional
      containsItems:
        - label: addTax
        - label: getRefund
    didChange:                                # optional
      - file: Target.v2.snapshot
        line: 137
        col:  37
        trigger: "."
        expect:
          containsItems: [{ label: addTax }]
```

### `textDocument/signatureHelp`

Cursor inside the call's parens. Trigger characters are typically `(`, `,`, `[`.

#### Minimum

```yaml
methods:
  textDocument/signatureHelp: {}
```

#### Fully-decked-out

```yaml
methods:
  textDocument/signatureHelp:
    line: 137
    col:  45                                  # inside func(arg1, |arg2)
    expect: { contains: "function addTax" }
```

For active-parameter advancement, position after a comma: `func(arg1, |arg2)` → param index 1.

---

## Rename

### `textDocument/rename`

Method-unique knob: `newName:`.

#### Minimum

```yaml
methods:
  textDocument/rename:
    newName: "renamedSymbol"
```

#### Fully-decked-out

```yaml
methods:
  textDocument/rename:
    line: 70
    col:  27
    newName: "owner_renamed"                  # required
    waitForProgressToken: "<token>"           # required for cross-file edits
    expect: { count: 14 }                     # optional: number of files with edits
    didChange:                                # optional: across an evolving file
      - file: Target.v2.snapshot
        line: 69
        col:  27
        expect: { count: 14 }
      - file: Target.v3.snapshot
        line: 69
        col:  27
        expect: { count: 16 }
```

Returns the WorkspaceEdit; does **not** apply to disk. Use `workspace/willRenameFiles` for the apply-and-restore lifecycle.

---

## Range-based (sub-range of a document)

`startLine`/`startCol` mark the start; the method's `line`/`col` mark the end.

### `textDocument/inlayHint`

#### Minimum

```yaml
initializeSettings:
  inlayHints:
    parameters: true                          # required — server gates hints on this

methods:
  textDocument/inlayHint:
    startLine: 0
    startCol:  0
    line: 100                                 # endLine
    col:  0                                   # endCol
```

#### Fully-decked-out

```yaml
initializeSettings:
  inlayHints:
    parameters: true
    gasEstimates: true

methods:
  textDocument/inlayHint:
    startLine: 130
    startCol:  0
    line: 147                                 # endLine
    col:  0                                   # endCol
    expect: { minCount: 1 }
```

### `textDocument/semanticTokens/range`

#### Minimum

```yaml
methods:
  textDocument/semanticTokens/range:
    startLine: 0
    startCol:  0
    line: 100                                 # endLine
    col:  0                                   # endCol
```

#### Fully-decked-out

```yaml
methods:
  textDocument/semanticTokens/range:
    startLine: 0
    startCol:  0
    line: 100
    col:  0
    expect: { minCount: 1 }
```

Range crossing only comments yields zero tokens — pick a representative ~50-line viewport.

---

## Whole-document (no cursor needed)

Applies to: `textDocument/formatting`, `textDocument/foldingRange`, `textDocument/documentLink`, `textDocument/documentSymbol`, `textDocument/codeLens`, `textDocument/diagnostic`, `textDocument/documentColor`, `textDocument/semanticTokens/full`, `textDocument/semanticTokens/full/delta`.

### Minimum

```yaml
methods:
  textDocument/foldingRange: {}
  textDocument/documentSymbol: {}
  textDocument/documentLink: {}
  textDocument/semanticTokens/full: {}
  # … etc
```

### Fully-decked-out — `textDocument/formatting`

```yaml
methods:
  textDocument/formatting:
    didChange:                                # send unformatted content first
      - file: Target.unformatted.snapshot
        line: 0
        col:  0
        expect: { minCount: 1 }
```

### Notes per method

- `formatting` — pair with `didChange:` to send unformatted content; the formatter returns `TextEdit[]` to canonicalize it.
- `documentSymbol` — server may return hierarchical `DocumentSymbol[]` or flat `SymbolInformation[]`. Bench treats both as flat for `minCount`.
- `codeLens`, `documentColor`, `diagnostic` — many Solidity LSPs don't implement these. Add to top-level `exclude:` if they return null.
- `semanticTokens/full/delta` — requires a prior `/full` request to seed; harness chains automatically. Some servers fall back to `/full` on stale state — timing then doesn't reflect a true delta.

---

## Diagnostic-driven

### `textDocument/codeAction`

Cursor on a position with an active diagnostic. Without one, the response is empty.

#### Minimum

```yaml
initializeSettings:
  lint:
    enabled: true                             # required to publish diagnostics

methods:
  textDocument/codeAction: {}
```

#### Fully-decked-out

```yaml
initializeSettings:
  lint:
    enabled: true

methods:
  textDocument/codeAction:
    line: 263
    col:  8
    expect: { titleContains: "Remove unused import" }
```

---

## Call hierarchy (chained)

`callHierarchy/incomingCalls` and `callHierarchy/outgoingCalls` require `prepareCallHierarchy` first to resolve the cursor. The harness chains automatically — only the second method needs configuring.

### Minimum

```yaml
methods:
  callHierarchy/incomingCalls: {}
  # or
  callHierarchy/outgoingCalls: {}
```

### Fully-decked-out

```yaml
methods:
  callHierarchy/incomingCalls:
    line: 50
    col:  20                                  # cursor on the function name
    waitForProgressToken: "<token>"           # required for cross-contract resolution
    expect: { minCount: 1 }
    cold: true                                # optional
```

Notes:
- If `prepareCallHierarchy` returns `null`, the chained call errors — fix the cursor.
- Pure / leaf functions return empty `outgoingCalls` (correct).
- Low-level dynamic calls (`.call()`, `.delegatecall()`) typically don't appear in `outgoingCalls` — they're resolver-opaque.

---

## Workspace-scoped

### `workspace/symbol`

Project-wide fuzzy symbol search. `file`/`line`/`col` are placeholders (any file works as the open anchor).

#### Minimum

```yaml
methods:
  workspace/symbol: {}
```

#### Fully-decked-out

```yaml
methods:
  workspace/symbol:
    waitForProgressToken: "<token>"           # required for full coverage
    expect: { minCount: 1 }
```

Default query is empty (returns all symbols).

### `workspace/executeCommand`

Method-unique knobs: `command:` (required), `arguments:` (default `[]`), `waitForProgress:` (gate timing on background work).

#### Minimum

```yaml
methods:
  workspace/executeCommand:
    command: "<server>.reindex"
    arguments: []
```

#### Fully-decked-out

```yaml
methods:
  workspace/executeCommand:
    command: "<server>.reindex"
    arguments: []
    waitForProgress: true                     # block on $/progress end after response
    expect: { shape: null }                   # most commands return null
```

### `workspace/willRenameFiles`, `workspace/willCreateFiles`, `workspace/willDeleteFiles`

These run via lifecycle steps. Method-unique knobs: `renameSteps:`, `createSteps:`, `deleteSteps:` (each is its own step shape — see `lifecycle-tests` topic skill).

#### Minimum

```yaml
initializeSettings:
  fileOperations:
    updateImportsOnRename: true
    templateOnCreate: true
    updateImportsOnDelete: true

methods:
  workspace/willRenameFiles:
    renameSteps:
      - { file: A.sol, newName: AA.sol }
  workspace/willCreateFiles:
    createSteps:
      - { file: src/NewContract.sol }
  workspace/willDeleteFiles:
    deleteSteps:
      - { file: src/ToBeDeleted.sol }
```

#### Fully-decked-out — `workspace/willRenameFiles`

```yaml
initializeSettings:
  fileOperations:
    updateImportsOnRename: true               # required

methods:
  workspace/willRenameFiles:
    waitForProgressToken: "<token>"           # required when LSP reindexes async
    renameSteps:
      - { file: A.sol,  newName: AA.sol, expect: { count: 1 } }
      - { file: AA.sol, newName: A.sol,  expect: { count: 1 } }
      - { file: A.sol,  newName: AA.sol, expect: { count: 1 } }   # round-trip
      - { file: AA.sol, newName: A.sol,  expect: { count: 1 } }
```

`expect.count` = number of *files* with edits.

---

## Method-knob compatibility matrix

Which cross-cutting knobs apply to which method?

| Knob (topic skill) | Position | Range / whole-doc | Workspace |
|---|---|---|---|
| `expect:` (`assert-results`) | ✅ all | ✅ all | ✅ all |
| `waitForProgressToken:` (`wait-for-token`) | ✅ when cross-file | ✅ rarely needed | ✅ for `symbol`, lifecycle |
| `waitForProgress:` (`wait-for-token`) | rarely | rarely | ✅ for `executeCommand` |
| `batch:` (`multi-file`) | ✅ idiomatic for refs/def/impl/highlight | rarely | rarely |
| `didChange:` (`evolve-the-file`) | ✅ all | ✅ all | rarely |
| `didOpen:` (`extra-files`) | ✅ when testing cross-file discovery growth | rarely | rarely |
| `cold:` (`cold-vs-warm`) | ✅ all | ✅ all | ✅ all |
| `initializeSettings:` (`custom-init-settings`) | ✅ when feature gated (inlay, lint) | ✅ same | ✅ for fileOperations |
| `renameSteps`/`createSteps`/`deleteSteps` (`lifecycle-tests`) | n/a | n/a | ✅ for `will*Files` |

## Method-unique knobs at a glance

| Method | Unique knob | Required? |
|---|---|---|
| `textDocument/completion` | `trigger:` | when fired by trigger char |
| `textDocument/rename` | `newName:` | yes |
| `textDocument/inlayHint` | `startLine`/`startCol` (range start) | yes |
| `textDocument/semanticTokens/range` | `startLine`/`startCol` | yes |
| `workspace/executeCommand` | `command:`, `arguments:`, `waitForProgress:` | `command:` required |
| `workspace/willRenameFiles` | `renameSteps:` | yes |
| `workspace/willCreateFiles` | `createSteps:` | yes |
| `workspace/willDeleteFiles` | `deleteSteps:` | yes |
