# Agent instructions

Keep CLI, domain behavior, validation, storage, fixtures, release checks, and tests in Kujo. Preserve immutable records, append-only history, atomic writes, bounded I/O, path/symlink protection, offline behavior, and authority boundaries. Run `/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo run tests/test.kujo` and `git diff --check`. Never force-push or use live credentials in tests.

Use `KUJO_BIN=/absolute/path/to/kujo bash scripts/validate.sh` for the full gate.
`tests/audit_test.kujo` covers boundary regressions; `tests/pagination_test.kujo`
covers bounded scans; CLI/concurrency suites take the runtime path after `--`.
See `docs/contracts.md` for cursor and audit validation semantics and
`docs/audits/repository-hardening.md` for measured baselines and unresolved limits.
