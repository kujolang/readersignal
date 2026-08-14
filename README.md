# ReaderSignal

[![Version](https://img.shields.io/badge/version-0.2.0-black)](VERSION)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)
[![built with Kujo](https://img.shields.io/badge/built%20with-Kujo-white.svg)](https://github.com/kujolang/kujo)
[![CI](https://github.com/kujolang/readersignal/actions/workflows/validate.yml/badge.svg)](https://github.com/kujolang/readersignal/actions/workflows/validate.yml)

ReaderSignal is a local-first Kujo tool for privacy-bounded measurement snapshots, feedback, comparisons, and evidence-linked learning. It has no required hosted service, database server, model key, or sibling-tool dependency.

## Readiness posture

ReaderSignal is ready for serious standalone workflows: immutable records, append-only audit events, atomic writes, per-record locks, bounded inputs and queries, structured errors, deterministic fixtures, strict domain contracts, and explicit authority boundaries. Optional external capabilities fail honestly when no adapter is configured. It does not claim hosted identity or distributed multi-host coordination.

See the [production review](docs/PRODUCTION_READINESS_REVIEW.md) and [next-session worklist](docs/NEXT_SESSION.md).

## Quick install

Requires Kujo 1.0.1 or newer.

```bash
git clone https://github.com/kujolang/readersignal.git
cd readersignal
export KUJO_BIN=/absolute/path/to/kujo
export PATH="$PWD/bin:$PATH"
readersignal --version --json
readersignal doctor --json
```

## Quick start

```bash
readersignal init --state .readersignal --json
readersignal snapshot --input fixtures/core.json --actor analyst --json
readersignal validate --json
readersignal export --output readersignal-export.json --json
```

Run `readersignal --help` for the complete command surface. Common flags include `--state`, `--config`, `--input`, `--actor`, `--timestamp`, `--id`, `--path`, `--type`, `--after`, `--limit`, `--output`, `--force`, `--dry-run`, and `--json`. JSON mode uses the stable `ok/data/error/error_code/tool_version/contract_version` envelope. Exit codes are 0 success, 1 operational failure, and 2 usage error.

State defaults to `.readersignal/`. Traversal, symlinks, secret-shaped fields, malformed JSON, incompatible schemas, duplicate IDs, checksum drift, oversized resources, and unsafe overwrites fail closed. Core behavior is implemented entirely in Kujo; adapters remain optional.

## Project structure

```text
readersignal.kujo       canonical entrypoint
src/                  CLI, domain, storage, and shared Kujo modules
tests/                regression, security, and domain suites
schemas/              public JSON contracts
fixtures/             deterministic offline inputs
scripts/              validation gates
docs/                 contracts, security, review, and future work
bin/readersignal        logic-free launcher
```

## Verification

```bash
bash scripts/validate.sh
```

The gate checks the entrypoint, every Kujo suite, JSON artifacts, CLI smoke paths, foreign-runtime boundaries, and the Git diff.
