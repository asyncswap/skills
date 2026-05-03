---
name: textDocument/documentSymbol
description: YAML for `textDocument/documentSymbol`. Outline of declarations (contracts, functions, structs, events, errors).
---

# bench `textDocument/documentSymbol`

```yaml
methods:
  textDocument/documentSymbol:
    expect: { minCount: 1 }
```

Whole-doc. Server may return hierarchical `DocumentSymbol[]` or flat `SymbolInformation[]`; bench treats both as flat for `minCount`.
