---
name: cold-vs-warm
description: Choose between cold-start and warm benches. Cold spawns a fresh server per iteration and includes startup + initial compile in the timing; warm reuses one server across iterations and measures steady-state response cost.
---

# Cold vs warm

## Default: warm

```yaml
iterations: 10
warmup: 2
```

The bench spawns the server once, opens the file, waits for diagnostics + (optionally) a progress token, then sends `iterations` measured requests after `warmup` discarded ones. Timings reflect steady-state response cost.

Use when you want to measure: response latency assuming the server is ready.

## Cold

```yaml
methods:
  textDocument/references:
    cold: true
    waitForProgressToken: "<token>"
```

Or set `cold: true` at the top level to apply to every method. With `cold:`:

- A fresh server is spawned per iteration
- The timer starts immediately before `textDocument/didOpen`
- Includes server startup + compile + indexing + the actual response

Use when you want to measure: what the user feels when opening a file and using a feature for the first time.

## When to use which

| Question | Mode |
|---|---|
| "How fast is the response on a hot project?" | warm |
| "Does this commit make hovers slower?" | warm (with multiple `servers:`) |
| "How long to first usable response after opening a file?" | cold |
| "Is startup time regressing across versions?" | cold |
| "Does background indexing block the first request?" | cold + `waitForProgressToken` (timing includes the wait) |

## Tuning

- Cold runs are slow — drop `iterations: 3, warmup: 0` so the bench finishes in reasonable time.
- Warm runs benefit from `warmup: 2` to let JIT/cache effects settle.
- Bump `index_timeout` (default 15s) to `60`–`300` for projects where the initial index takes longer.

## Common pitfalls

- Comparing cold timings across machines is unreliable — startup cost varies with disk speed, locale init, etc.
- Forgetting `waitForProgressToken` in cold mode: the request fires before background work finishes → partial response. The timing looks fast but the response is wrong.
