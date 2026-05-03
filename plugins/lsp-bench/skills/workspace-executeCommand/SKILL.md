---
name: workspace/executeCommand
description: YAML for `workspace/executeCommand`. Invokes a server command; set `waitForProgress: true` if the command kicks off background work you want included in the timing.
---

# bench `workspace/executeCommand`

```yaml
methods:
  workspace/executeCommand:
    command: "solidity.reindex"
    arguments: []
    waitForProgress: true       # block on $/progress end after the response
```

Many commands return immediately and continue work in the background. Without `waitForProgress` timings capture only the dispatch. For commands that emit no progress events, leave it `false` (else the bench blocks until `index_timeout`).
