---
name: cold-vs-warm
description: Manage how the LSP is run during a benchmark — restart it for every iteration (cold) or reuse one initialized session across iterations (warm). Use cold to measure what the user feels on first use; use warm to measure steady-state response cost.
---

# LSP session lifecycle: restart per iteration vs reuse

Two modes for how the bench runs the LSP across iterations.

## Reuse one session (warm) — the default

```yaml
iterations: 10
warmup: 2
```

The bench spawns the LSP **once**, opens the file, waits for diagnostics + (optionally) a progress token, then sends `iterations` measured requests after `warmup` discarded ones. The LSP stays alive across all of them; caches are hot. Timings reflect steady-state response cost.

Use this to measure: how fast the response is once the server is ready.

## Restart per iteration (cold)

```yaml
methods:
  textDocument/references:
    cold: true
    waitForProgressToken: "<token>"
```

Or set `cold: true` at the top level to apply to every method. With cold mode:

- A fresh LSP is spawned for every iteration
- The timer starts immediately before `textDocument/didOpen`
- Includes server startup + compile + indexing + the actual response

Use this to measure: what the user feels when opening a file and using a feature for the first time.

## When to use which

| Question | Mode |
|---|---|
| "How fast is the response on a hot project?" | reuse (warm) |
| "Does this commit make hovers slower?" | reuse (warm), with multiple `servers:` |
| "How long to first usable response after opening a file?" | restart (cold) |
| "Is startup time regressing across versions?" | restart (cold) |
| "Does background indexing block the first request?" | restart (cold) + `waitForProgressToken` (timing includes the wait) |

## Tuning

- Restart-per-iteration (cold) runs are slow — drop `iterations: 3, warmup: 0` so the bench finishes in reasonable time.
- Reuse-session (warm) runs benefit from `warmup: 2` to let JIT/cache effects settle.
- Bump `index_timeout` (default 15s) to `60`–`300` for projects where the initial index takes longer.

## Common pitfalls

- Comparing cold timings across machines is unreliable — startup cost varies with disk speed, locale init, etc.
- Forgetting `waitForProgressToken` in cold mode: the request fires before background work finishes → partial response. The timing looks fast but the response is wrong.
