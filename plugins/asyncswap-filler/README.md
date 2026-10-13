# Async Swap filler

Agent instructions and a launcher for discovering orders, evaluating supplied
USDC valuations, and preparing unsigned fills or Unichain bundle requests.
The plugin never signs or broadcasts transactions.

## Prerequisites

- Bun.
- An application checkout containing `packages/filler-tools` version 0.1.0 and
  the `prepare-bundle` command, with dependencies installed. The CLI remains
  under development and is **not published to npm**. Installing this plugin
  alone does not install the implementation.
- An operator-approved configuration, accessible filler API/RPC, and a trusted
  quote source for valuation. No wallet private key is needed.

Set the checkout location in the agent's environment:

```sh
export ASYNCSWAP_FILLER_ROOT="/absolute/path/to/application-checkout"
```

For a persistent local setup, the launcher also reads the checkout path from
`${XDG_CONFIG_HOME:-$HOME/.config}/asyncswap/filler-root` when the environment
variable is unset. This file contains only the absolute path, without quotes.

The launcher does not clone repositories, install dependencies, or change wallet
configuration. Install dependencies in the application checkout using its normal
Bun setup before invoking it.

## Installation

Install from the marketplace:

```
/plugin marketplace add asyncswap/skills
/plugin install asyncswap-filler@asyncswap
```

For development, point your agent's local plugin loader at `plugins/asyncswap-filler`,
or load [the skill](skills/asyncswap-filler/SKILL.md) directly. The skill directory
is self-contained and can also be copied to a supported agent skill directory;
keep its `scripts` and `references` folders together.

From this repository, verify the launcher:

```sh
bash plugins/asyncswap-filler/skills/asyncswap-filler/scripts/filler.sh --help
```

Example request to the agent: “Use the Async Swap filler skill to inspect open
orders on my configured chain and prepare a Unichain bundle if the valuation
meets my limits. Do not submit it.”

See [the tool reference](skills/asyncswap-filler/references/tools.md) for JSON
schemas, setup, and simulation limitations.

## Maintaining the skill

This repository is the canonical source for the skill, launcher, and bundled
reference. Implementation and contract tests remain in the application repo.
When tool schemas change, update this reference with the implementation change.

To refresh the development copy in an application checkout:

```sh
bun run scripts/sync-filler-skill.ts "$ASYNCSWAP_FILLER_ROOT"
```

This copies the canonical files to `.agents/skills/asyncswap-filler` and overwrites
matching files there. Edit the canonical source here, then sync; do not maintain
the development copy separately. No transaction or configuration files are copied.
