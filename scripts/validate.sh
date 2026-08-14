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
"$KUJO_RUNTIME" run tests/storage_test.kujo
"$KUJO_RUNTIME" run tests/domain_test.kujo
"$KUJO_RUNTIME" run tests/hardening_test.kujo
while IFS= read -r document; do "$KUJO_RUNTIME" run scripts/validate_json.kujo -- "$document"; done < <(find fixtures schemas -type f -name '*.json' -print | sort)
tmp_state="$(mktemp -d)"; trap 'find "$tmp_state" -depth -delete' EXIT
KUJO_BIN="$KUJO_RUNTIME" ./bin/readersignal --help >/dev/null
KUJO_BIN="$KUJO_RUNTIME" ./bin/readersignal --version --json >/dev/null
KUJO_BIN="$KUJO_RUNTIME" ./bin/readersignal doctor --state "$tmp_state/state" --json >/dev/null
if grep -REn --include='*.kujo' 'python3|node |\.py\b|\.mjs\b' src tests scripts readersignal.kujo kujo.toml; then
  printf 'readersignal validation failed: foreign runtime dependency reference found.\n' >&2; exit 1
fi
test ! -f package.json && test ! -f requirements.txt && test ! -f go.mod && test ! -f Cargo.toml
badge_line() { grep -En -m 1 "$1" README.md 2>/dev/null | cut -d: -f1 || true; }
version_badge="$(badge_line 'shields.io/badge/version-')"
license_badge="$(badge_line 'shields.io/badge/license-')"
kujo_badge="$(badge_line 'shields.io/badge/built%20with-Kujo-')"
ci_badge="$(badge_line 'actions/workflows/validate.yml/badge.svg')"
if [[ -z "$version_badge" || -z "$license_badge" || -z "$kujo_badge" || -z "$ci_badge" ]] ||
   ! (( version_badge < license_badge && license_badge < kujo_badge && kujo_badge < ci_badge )); then
  printf 'validation failed: README badges must be ordered version, license, built with Kujo, then CI.\n' >&2
  exit 1
fi
if ! grep -Eq '^# Kujo ecosystem local artifact ignore block\.$' .gitignore ||
   ! git check-ignore -q .loop-engineering/loop.yml; then
  printf 'validation failed: the standard Kujo local-artifact ignore block is missing or incomplete.\n' >&2
  exit 1
fi
if [[ -n "$(git ls-files '.loop-engineering/**')" ]]; then
  printf 'validation failed: Loop Engineering evidence must remain local and untracked.\n' >&2
  exit 1
fi
git diff --check -- . ':(exclude).loop-engineering/**'
printf 'readersignal validation passed.\n'
