---
name: code-cleanup
description: Fix Solidity code quality issues using LSP diagnostics and structural analysis. Reacts to live diagnostics (naming, gas, safety, unused imports) published by the Solidity Language Server, and uses LSP findReferences for safe cross-file renames. Detects dead code via LSP reference counting. Use when asked to clean up, fix warnings, or improve code quality.
argument-hint: [file-path] [--fix] [--category naming|gas|safety|style|dead-code|all]
allowed-tools: LSP Grep Glob Read Edit
---

# Solidity Code Cleanup

Fix code quality issues using live LSP diagnostics and LSP structural analysis. The Solidity Language Server publishes diagnostics in `<new-diagnostics>` blocks **as a side effect of LSP requests** (not `Read` alone) — this skill triggers those requests, reads the diagnostics, and applies fixes using LSP-guided refactoring.

## How it works

The Solidity Language Server publishes diagnostics in response to LSP requests (e.g., `documentSymbol`, `hover`, `findReferences`). They appear in the conversation as `<new-diagnostics>` blocks, one line per finding, in roughly this shape:

```
ℹ [Line 6:8] use named imports '{A, B}' or alias 'import ".." as X' [unaliased-plain-import] (forge-lint)
```

The trailing `[lint-code]` and `(source)` identify the rule; the `[Line L:C]` prefix gives 1-based line and column.

This skill collects those diagnostics, categorizes them, and uses LSP operations (`findReferences`, `documentSymbol`, `goToDefinition`) to apply safe fixes across the codebase.

> **Important:** `Read` alone does **not** flush diagnostics. Always pair a `Read` with at least one LSP request — see Step 1 for the canonical procedure. Every other step that says "Read the file to see fresh diagnostics" implies the same warm-up.

## Input

- `$ARGUMENTS` — Parse the arguments:
  - **file-path** (optional): Specific file to clean up. If omitted, fix all diagnostics visible in the current conversation.
  - **--fix** (optional): Apply fixes automatically for safe categories (naming, style). Safety and gas fixes are always presented as choices.
  - **--category** (optional): `naming`, `gas`, `safety`, `style`, `dead-code`, `all` (default).

## Phase 1: Collect Diagnostics

### Step 1: Gather current diagnostics

Check the conversation for all `<new-diagnostics>` blocks. Extract each diagnostic entry.

If no diagnostics are visible yet for the target file(s), trigger them:

1. `Read` the file. This opens it in the server but does **not** reliably publish diagnostics on its own.
2. Issue a warm-up LSP request that forces analysis — `documentSymbol` on the file is the cheapest probe that touches the whole document. `workspaceSymbol` or `hover` also work.
3. Re-check the conversation for a fresh `<new-diagnostics>` block. The diagnostics arrive as a side effect of the LSP request, not the Read.

A silent Read with no diagnostics block is **not** evidence the file is clean — it only means the server hasn't been asked to analyze yet. Always pair the Read with at least one LSP call before concluding "no issues".

### Step 2: Categorize

| Category | Lint Codes | Auto-fixable? |
|---|---|---|
| **naming** | `screaming-snake-case-immutable`, `screaming-snake-case-constant`, `mixed-case-function`, `mixed-case-variable` | YES — mechanical rename via LSP findReferences |
| **gas** | `asm-keccak256`, `asm-mstore` | NO — present as suggestion |
| **safety** | `erc20-unchecked-transfer`, `divide-before-multiply` | NO — present options |
| **style** | `unwrapped-modifier-logic`, `unused-import`, `unaliased-plain-import` | YES — safe to apply |

**Unmapped lint codes:** if a diagnostic's lint code isn't listed above, default to **style** (interactive — show the diagnostic, offer to apply, do not auto-fix). Add the code to this table once its category is confirmed.

## Phase 2: LSP Structural Analysis

### Step 3: Reference lookup for renames

For each **naming** diagnostic (e.g., `router` should be `ROUTER`):

1. Use `LSP findReferences` on the symbol at the flagged line and column
2. Collect ALL reference sites across all files (definition + every usage)
3. Verify the new name doesn't collide: `Grep` for the proposed name in the codebase
4. Generate Edit operations for the definition + every reference site
5. Apply edits starting from the last file/line to avoid offset shifts

### Step 4: Dead code detection

Use `LSP documentSymbol` on the target file(s) to list all functions. For each `internal` or `private` function:

1. `LSP findReferences` at the function definition line
2. Count references. If the result includes the definition site, subtract it; otherwise count as-is. (Server-dependent — Solidity LSPs vary on whether the definition is included in `findReferences` results.)
3. Zero external references = dead code candidate

**Only flag internal/private functions.** Public/external functions may be called by contracts outside the codebase.

### Step 5: Unused import detection

If `unused-import` diagnostics are present from the LSP, use them directly.

Otherwise, fall back to grep-based detection per import shape:

- `import {A, B as C} from "./X.sol";` — extract each named symbol (`A`, `C`); grep the file body for each. Zero matches = that symbol's import is unused. If all named symbols are unused, the whole line can go.
- `import "./X.sol" as Foo;` — grep for `Foo.` (with the dot) in the body. Zero matches = unused.
- `import "./X.sol";` (plain, unaliased) — cannot reliably tell from grep alone, since the file's exports enter the global namespace. Defer to the LSP `unaliased-plain-import` / `unused-import` diagnostic instead of guessing.

Only delete an import when the LSP confirms it OR (for the first two shapes) grep finds zero usages in the body.

## Phase 3: Fix Application

### Step 6: Apply fixes by category

**Naming (auto-fix with --fix):**

1. Read the diagnostic message to determine the suggested name (e.g., `router` → `ROUTER`)
2. Use `LSP findReferences` to get every usage site across all files
3. Apply targeted `Edit` calls per reference site — **do not use `replace_all`**. The identifier may appear in comments, strings, or as a substring of unrelated names (`routerAddress`, `// router config`); only `findReferences` knows the real symbol sites.
4. Verify per Step 7 (Read + warm-up LSP request) that the naming diagnostic is gone

**Style (auto-fix with --fix):**

- `unused-import`: Read the file, identify the flagged import line, delete it with Edit
- `unaliased-plain-import` (`import "./X.sol";`): rewrite to either named imports `import {A, B} from "./X.sol";` (preferred — grep the body for which symbols from `X.sol` are actually used) or a namespace alias `import "./X.sol" as X;` (use when many symbols are pulled in or names would collide). Don't auto-pick if both rewrites would compile differently — ask the user.
- `unwrapped-modifier-logic`: Read the modifier body, extract logic into an `_internal` function, replace modifier body with a call to it. Use `LSP findReferences` to check the new function name doesn't collide.

**Safety (always interactive — present options, do not auto-apply):**

- `erc20-unchecked-transfer`: Read the flagged line and surrounding context (5 lines). Present options:
  1. Wrap with return value check: `if (!token.transfer(...)) revert TRANSFER_FAILED()`
  2. Use SafeERC20: `token.safeTransfer(...)` (requires import)
  3. Use low-level call pattern (if the codebase already uses this elsewhere — check with Grep)
- Recommend the option that matches existing patterns in the codebase

**Gas (suggestion only — do not apply unless explicitly asked):**

- `asm-keccak256`: Read the flagged `keccak256(abi.encode(...))` expression. Show the inline assembly equivalent as a suggestion. Note the readability tradeoff.
- Present the suggestion but do NOT apply by default

### Step 7: Verify after fixes

After applying any edit:

1. Read the edited file, then issue a warm-up LSP request (`documentSymbol`) to flush fresh diagnostics — Read alone is not sufficient (see Step 1)
2. Check that the fixed diagnostic no longer appears in the new `<new-diagnostics>` block
3. If new errors appear (e.g., compilation error from a bad rename), report and revert

## Phase 4: Preview-Then-Apply Output

**Never apply fixes silently.** Always show the diff first, then apply only after presenting it. This phase formalizes how Phase 3 actually emits changes.

### Step 8: Show the cleanup summary

```
## Code Cleanup — <file or directory>

| Category | Issues | Fixable | Description |
|---|---|---|---|
| naming | 2 | 2 | `router` → `ROUTER`, ... |
| gas | 5 | 0 | keccak256 inline assembly |
| safety | 2 | 0 | unchecked ERC-20 transfer |
| style | 1 | 1 | unwrapped modifier logic |
| dead-code | 0 | — | — |
```

### Step 9: Present each fix as a diff BEFORE applying

For each fixable issue, read the file, construct the old and new strings, and present the change as a diff block in your text output:

```diff
 // File: AsyncSwap.sol:40
- AsyncRouter public immutable router;
+ AsyncRouter public immutable ROUTER;
```

```diff
 // File: AsyncSwap.sol:292
- router.executeSwap{value: msg.value}(
+ ROUTER.executeSwap{value: msg.value}(
```

```diff
 // File: AsyncSwap.sol:189
- router.withdrawNative(to, amount);
+ ROUTER.withdrawNative(to, amount);
```

For renames, list ALL reference sites from `LSP findReferences` so the user sees the full blast radius before any edits happen.

### Step 10: Apply with Edit tool

After presenting the diffs, apply each change using the `Edit` tool. The Edit tool shows its own diff to the user for approval. Apply changes one file at a time, starting from the bottom of each file (highest line number first) to avoid offset drift.

For cross-file renames:

1. Present ALL diffs across all files in one text block
2. Apply edits file by file — definition site first, then usage sites
3. After all edits, run the verification procedure from Step 7 on each touched file (Read + warm-up `documentSymbol`)
4. Confirm the diagnostic is resolved (no longer appears)

### Step 11: Present non-fixable issues as choices

For safety issues, present options with diffs for each:

erc20-unchecked-transfer — CurrencySettler.sol:18

Current:
  IERC20(token).transferFrom(payer, address(manager), amount);

Option A:

```diff
- IERC20(token).transferFrom(payer, address(manager), amount);
+ if (!IERC20(token).transferFrom(payer, address(manager), amount)) revert();
```

Option B:

```diff
+ import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
  ...
- IERC20(token).transferFrom(payer, address(manager), amount);
+ SafeERC20.safeTransferFrom(IERC20(token), payer, address(manager), amount);
```

Option C: Keep as-is (codebase uses low-level .call() pattern elsewhere)

For gas suggestions, show the before/after but mark as optional:

asm-keccak256 — AsyncSwap.sol:537 (×5 instances)

```diff
- bytes32 orderId = keccak256(abi.encode(order));
+ bytes32 orderId;
+ assembly {
+     let ptr := mload(0x40)
+     mstore(ptr, mload(order))
+     mstore(add(ptr, 0x20), mload(add(order, 0x20)))
+     mstore(add(ptr, 0x40), mload(add(order, 0x40)))
+     orderId := keccak256(ptr, 0x60)
+ }
```

Saves ~30 gas per call. Reduces readability. Apply only if gas is a priority.

### Step 12: Verify

After all edits, run the Step 7 procedure on each modified file (Read + warm-up `documentSymbol`). Check:

- The fixed diagnostic no longer appears in `<new-diagnostics>`
- No new error diagnostics were introduced
- If a new error appears, show it and offer to revert

## Reactive Mode

This skill works best reactively during development:

1. User writes or edits Solidity code
2. As the assistant uses LSP requests in the course of work, the server publishes diagnostics in `<new-diagnostics>` blocks
3. User says "fix those warnings" or "clean up"
4. Skill reads the diagnostics from conversation context (or runs Step 1 to flush them if absent)
5. Presents diffs for each fix
6. Applies via Edit tool (user sees each change for approval)
7. Runs the Step 7 verification procedure on each touched file
