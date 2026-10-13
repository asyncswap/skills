#!/usr/bin/env bash
set -euo pipefail

filler_root="${ASYNCSWAP_FILLER_ROOT:-}"
root_file="${XDG_CONFIG_HOME:-$HOME/.config}/asyncswap/filler-root"
if [[ -z "$filler_root" && -f "$root_file" ]]; then
  IFS= read -r filler_root < "$root_file" || true
fi
if [[ -z "$filler_root" || "$filler_root" != /* ]]; then
  echo 'Set ASYNCSWAP_FILLER_ROOT to the absolute path of a checkout containing packages/filler-tools.' >&2
  exit 2
fi
cli="$filler_root/packages/filler-tools/src/cli.ts"
if [[ ! -f "$cli" ]]; then
  echo 'The configured checkout is missing packages/filler-tools/src/cli.ts. Use the checkout with the filler implementation.' >&2
  exit 2
fi
if ! command -v bun >/dev/null 2>&1; then
  echo 'Bun is required to run the filler tools.' >&2
  exit 2
fi
# Preserve caller-relative config/request paths. Bun resolves imports from the CLI.
exec bun run "$cli" "$@"
