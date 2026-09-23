# ReaderSignal

[![Version](https://img.shields.io/badge/version-0.2.0-black)](VERSION)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)
[![built with Kujo](https://img.shields.io/badge/built%20with-Kujo-white.svg)](https://github.com/kujolang/kujo)
[![CI](https://github.com/kujolang/readersignal/actions/workflows/validate.yml/badge.svg)](https://github.com/kujolang/readersignal/actions/workflows/validate.yml)

ReaderSignal is a local-first Kujo tool for privacy-bounded measurement snapshots, feedback, comparisons, and evidence-linked learning. It has no required hosted service, database server, model key, or sibling-tool dependency.

## Production capabilities

ReaderSignal provides immutable records, append-only audit events, atomic file writes, exclusive per-record locks, journal-backed process-crash recovery, and bounded query pages. Kujo module helpers provide privacy-preserving adapter checks, retention decisions, uncertainty-aware sample comparisons, optional signed PressWire verification, and real 100,000-snapshot compaction checks. The CLI compares stored payloads; statistical sampling and retention decisions are module APIs. It does not claim hosted identity or causal attribution.

See the [production review](docs/PRODUCTION_READINESS_REVIEW.md) and completed [hardening worklist](docs/NEXT_SESSION.md).

## Quick install

Requires POSIX Kujo 1.4.0 with `file_lock` and `list_dir_page`: revision
`cf785c0a7953717af16b657cda05b85d628144c5` (the CI pin) or a compatible newer
build. Version 1.4.0 alone does not identify these preview APIs.

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

State defaults to `.readersignal/`. Traversal, symlinks at managed/input file boundaries, secret-shaped fields, malformed JSON, incompatible schemas, duplicate IDs, checksum drift, oversized resources, and unsafe overwrites fail closed. Core behavior is implemented entirely in Kujo; adapters remain optional.

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

The gate checks the entrypoint, every Kujo suite (including concurrent writers and pagination), JSON artifacts, CLI behavior, runtime boundaries, and the Git diff. Test state is isolated and cleaned by the gate.

See [the hardening audit](docs/audits/repository-hardening.md) for measured results and [security boundaries](docs/security.md) for crash recovery and trusted-parent assumptions. Run `kujo run scripts/benchmark.kujo` for the repeatable compaction measurement.

## Recover an interrupted write

```bash
readersignal recover --state .readersignal --id snapshot-example --actor operator --dry-run --json
readersignal recover --state .readersignal --id snapshot-example --actor operator --json
```

Recovery replays a validated write intent, refuses active writers and conflicting
files, and appends a recovery receipt. Legacy locks without journals need offline
review; recovery never invents missing historical evidence. See
[recovery and paging](docs/recovery-and-paging.md) for upgrade and failure semantics.

For read-only legacy recovery diagnosis, use `readersignal recovery-status --state PATH --id ID --json`. See the [remaining-work review](docs/audits/completion.md) for safe restore procedures and durability boundaries.
