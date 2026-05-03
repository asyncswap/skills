---
name: wait-for-token
description: Make the bench wait for a specific LSP `$/progress` token before sending the request, or wait for a progress token to end *after* the response. Use when the request depends on background work (project indexing, sub-cache loading, custom build steps).
---

# Wait for an LSP progress token

By default the bench fires the request as soon as diagnostics arrive — which can be before background work (indexing, cross-file symbol resolution, etc.) has settled. Two keys control this.

## Wait *before* the request — `waitForProgressToken`

```yaml
methods:
  textDocument/references:
    waitForProgressToken: "<token>"
```

The bench drains `$/progress` notifications until it sees one with `kind: end` whose `token` matches. Other progress events (different tokens, `kind: begin`/`report`) are ignored. Only after the matching `end` does the actual request go out.

## Wait *after* the response — `waitForProgress`

```yaml
methods:
  workspace/executeCommand:
    command: "myserver.reindex"
    arguments: []
    waitForProgress: true
```

After the response is received, the bench blocks until the next `$/progress end` (any token). Useful when the response itself returns instantly but kicks off background work you want to include in the timing.

## Which to use

- **`waitForProgressToken`** when there's a *known* setup phase that must finish before your method makes sense.
- **`waitForProgress`** when the *method itself* triggers background work and you want end-to-end timing.

## Common pitfalls

- Use the **exact** token string the server emits (case-sensitive). Run with `-v` and grep the trace for `progress` lines to find it.
- Bump `index_timeout` if the work takes longer than 15s (`index_timeout: 60` or `300` for large projects).
- `waitForProgress: true` with a server that emits no progress events will block until `index_timeout` — leave it `false` for those.
