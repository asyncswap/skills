---
name: workspace/symbol
description: YAML for `workspace/symbol`. Project-wide fuzzy symbol search.
---

# bench `workspace/symbol`

```yaml
methods:
  workspace/symbol:
    waitForProgressToken: "solidity/projectIndexFull"
    expect: { minCount: 1 }
```

`file`/`line`/`col` are placeholders — the search is project-wide. Default query is empty (returns all symbols). Without `waitForProgressToken` results are a subset of what's been compiled so far.
