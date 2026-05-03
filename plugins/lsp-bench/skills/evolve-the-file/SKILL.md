---
name: evolve-the-file
description: Run the same LSP method across a sequence of file edits via `didChange:` snapshots. Use when you want to see how a method's response changes as the file evolves — added callers, shifted positions, new modifier usages, etc.
---

# Sequence of edits with `didChange:`

`didChange:` sends snapshots of the file content via `textDocument/didChange` between iterations. Each step has its own `(line, col)` because edits shift positions.

## Simple

```yaml
methods:
  textDocument/references:
    line: 70
    col:  27
    didChange:
      - file: target.v2.snapshot
        line: 69
        col:  27
      - file: target.v3.snapshot
        line: 69
        col:  27
```

The bench runs the method N+1 times (baseline + one per snapshot). Each snapshot file holds the full edited content; the bench buffers it via `didChange` so the LSP recompiles before the next request.

## Why per-step `(line, col)`

When the edit inserts code above your cursor, the original line shifts. The skill conventionally annotates each step with a comment explaining the shift:

```yaml
methods:
  textDocument/definition:
    line: 137                # PRICE — immutable declared at line 68
    col:  32
    didChange:
      - file: Shop.v2.snapshot
        line: 142
        col:  32
        # PRICE shifted (getPrice added above)
      - file: Shop.v3.snapshot
        line: 138
        col:  32
        # PRICE same offset (event/error added at bottom — below cursor)
      - file: Shop.v4.snapshot
        line: 144
        col:  32
        # PRICE shifted (both edits combined)
```

## Stable cursor (cursor above all edits)

If the cursor sits above every edit, positions stay constant — useful for checking response stability:

```yaml
methods:
  textDocument/hover:
    line: 42
    col:  13
    # addTax — function in library section, above all edits
    didChange:
      - { file: target.v2.snapshot, line: 41, col: 13 }
      - { file: target.v3.snapshot, line: 41, col: 13 }
      - { file: target.v4.snapshot, line: 41, col: 13 }
```

(The line shifts by 1 because the snapshot file itself differs — adjust to match.)

## Per-step `expect:`

Combine with `expect:` to assert how the response evolves:

```yaml
methods:
  textDocument/references:
    expect: { minCount: 14 }                      # baseline
    didChange:
      - file: target.v2.snapshot
        expect: { minCount: 14 }                  # same — edit added no new refs
      - file: target.v3.snapshot
        expect: { minCount: 16 }                  # +2 new usages
```

## Common pitfalls

- Snapshot files must contain the **full** edited file content, not a diff. The bench sends them whole via `didChange`.
- Each step's `(line, col)` must point at the same logical symbol after that snapshot's edits — get the line/col wrong and the response shifts to whatever's now under the cursor (often a misleading wide-reach result).
- If the LSP caches per-file builds aggressively, the bench's `didChange` triggers a recompile but downstream cross-file state may lag — pair with `waitForProgressToken` if cross-file results matter.
