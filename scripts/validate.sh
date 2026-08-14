#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_RUNTIME="${KUJO_BIN:-$ROOT/../kujo/target/release/kujo}"
if [[ ! -x "$KUJO_RUNTIME" ]] && command -v kujo >/dev/null 2>&1; then KUJO_RUNTIME="$(command -v kujo)"; fi
if [[ ! -x "$KUJO_RUNTIME" ]]; then printf 'readersignal: Kujo runtime not found; set KUJO_BIN.\n' >&2; exit 2; fi
cd "$ROOT"
"$KUJO_RUNTIME" check readersignal.kujo
"$KUJO_RUNTIME" run tests/test.kujo
"$KUJO_RUNTIME" run tests/security_test.kujo
"$KUJO_RUNTIME" run tests/domain_test.kujo
while IFS= read -r document; do "$KUJO_RUNTIME" run scripts/validate_json.kujo -- "$document"; done < <(find fixtures schemas -type f -name '*.json' -print | sort)
tmp_state="$(mktemp -d)"; trap 'find "$tmp_state" -depth -delete' EXIT
KUJO_BIN="$KUJO_RUNTIME" ./bin/readersignal --help >/dev/null
KUJO_BIN="$KUJO_RUNTIME" ./bin/readersignal --version --json >/dev/null
KUJO_BIN="$KUJO_RUNTIME" ./bin/readersignal doctor --state "$tmp_state/state" --json >/dev/null
if rg -n 'python3|node |\.py\b|\.mjs\b' src tests scripts/*.kujo readersignal.kujo kujo.toml; then
  printf 'readersignal validation failed: foreign runtime dependency reference found.\n' >&2; exit 1
fi
test ! -f package.json && test ! -f requirements.txt && test ! -f go.mod && test ! -f Cargo.toml
git diff --check -- . ':(exclude).loop-engineering/**'
printf 'readersignal validation passed.\n'
