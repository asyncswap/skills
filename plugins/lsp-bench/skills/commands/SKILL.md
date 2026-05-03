---
name: commands
description: Invoke a server-defined command via `workspace/executeCommand`. Set `waitForProgress: true` if the command kicks off background work you want to include in the timing.
---

# Server-defined commands — `workspace/executeCommand`

LSP servers can register commands (e.g., `<server>.reindex`, `<server>.clearCache`, custom workflows). The bench invokes them and optionally blocks on the resulting background work.

## Simple

```yaml
methods:
  workspace/executeCommand:
    command: "<command-name>"
    arguments: []
```

`command` is a string defined by the server. `arguments` is a JSON array forwarded to the command handler.

## End-to-end timing — `waitForProgress`

Many commands return immediately and continue work in the background. Without a wait, the bench timing captures only the dispatch. Set `waitForProgress: true` to block on the next `$/progress end` after the response:

```yaml
methods:
  workspace/executeCommand:
    command: "<server>.reindex"
    arguments: []
    waitForProgress: true
```

Now the iteration time reflects: dispatch → response → background work → progress end.

## Multiple commands

To bench more than one command in the same config, use `iterations: 1` per-method and stack methods at the top level:

```yaml
benchmarks:
  - workspace/executeCommand
methods:
  workspace/executeCommand:
    command: "<server>.reindex"
    arguments: []
    waitForProgress: true
```

(For different commands, currently re-run the bench with the changed `command` — there's no built-in multi-command iteration.)

## Common pitfalls

- `arguments` shape is server-specific. Empty array `[]` is the safe default for no-arg commands.
- `waitForProgress: true` against a command that emits no progress events will block until `index_timeout` — leave it `false` for those commands.
- Many commands have side effects that persist across iterations (cache wiped, files re-indexed). Bench results from later iterations may differ from the first — use `iterations: 1` if that distorts the measurement.
