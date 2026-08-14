# ReaderSignal

Audience-response and editorial-learning records for measurements, feedback, attribution limits, comparisons, and follow-up recommendations.

ReaderSignal 0.1.0 is an independently installable, local-first Kujo tool. It requires no hosted service, Chain of Command, WebOps, or sibling Publishing House tool. The canonical entrypoint is `readersignal.kujo`; `bin/readersignal` contains no product logic.

## CLI

Commands: snapshot; provider add; sync; feedback add; compare; signals; learn; followup; report; export; doctor; version; init; show; validate; history. Run `./bin/readersignal help` for flags. Mutations require `--actor`; JSON input uses `--input`. Common flags include `--json`, `--dry-run`, `--state`, `--output`, `--config`, and `--force`. Exit codes: 0 success, 1 validation/operation failure, 2 usage error.

State defaults to `.readersignal/`. Immutable JSON records and append-only history use atomic writes. IDs reject traversal; symlinks and oversized inputs are rejected. See [contracts](docs/contracts.md), [security](docs/security.md), and [quickstart](examples/quickstart.md).

Test with `/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo run tests/test.kujo`, then run `./bin/readersignal doctor --json`.

0.1.0 covers the documented local records, fixtures, validation, checksums, deterministic fixed-time IDs, and structured export. It does not manufacture human judgment, consent, rights, approval, or causation. 0.1.0 supports manual JSON snapshots, deterministic fixtures, and PressWire receipt imports; live analytics providers are unavailable optional adapters, and correlation is never represented as causation.
