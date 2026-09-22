# Contracts

Contract 1.0.0. ReaderSignal owns: Publication Measurement; Metric Definition; Measurement Window; Audience Response; Feedback Record; Attribution Boundary; Editorial Learning; Follow-Up Recommendation. Records carry schema/tool versions, stable IDs, actor, timestamp, provenance, command, and payload. Consumers accept compatible 1.x, preserve safe unknown payload metadata, and reject incompatible majors. JSON uses `ok/data/error/tool_version/contract_version`. Offline upstream fixtures identify repository, tag, schema, and checksum.

Hardening contracts add identifier-free aggregate adapter conformance, policy-versioned retention/deletion receipts, 30..100,000-observation comparisons with sample sizes, standard error and 95% confidence intervals, optional explicit-key PressWire receipt verification, and compaction of up to 100,000 snapshots into at most 256 bounded rollups.

## Hardening clarifications (2026-09-22)

- The envelope also requires `error_code`; success uses null error fields.
  `--version --json` has the same envelope as `version --json`.
- CLI usage errors exit 2; operational/validation failures exit 1. Missing flag
  values are usage errors. Configuration types follow `schemas/config.schema.json`.
- Dry runs validate state compatibility and payloads without creating directories
  or metadata. Failed payload validation also leaves fresh state untouched.
- Listing/export adds `next_cursor`; listing also adds `scanned`. Pass the returned
  cursor verbatim to `--after`. It is an opaque bounded filename cursor, including
  corrupt filenames, and is never used as a filesystem path. Empty filtered pages
  can still be truncated. Continue until `truncated` is false.
- Pages examine at most 1,000 candidates and retain at most 4 MiB of record source
  bytes, in addition to the requested 1..1,000 result count. Directory enumeration time
  remains proportional to directory size; name buffering is capped at 1,001. Export enforces 8 MiB for both stdout
  and file destinations; smaller pages can be requested with `--limit`.
- `validate` checks creation-event identity/checksum and returns
  `validation_incomplete` when another page remains. Resume using `--after` and
  `next_cursor`; success concerns that completed page, not earlier pages.
  `doctor` returns `inspection_incomplete` rather than a whole-state health claim
  when its page is truncated. Neither command reconstructs missing evidence.
- Record schema accepts existing 0.1.0 and current 0.2.0 records under contract
  1.0.0. Audit evidence must match either version. Calendar-invalid timestamps,
  nonfinite/overflowed metrics, malformed snapshots, and nested direct identifiers
  are invalid inputs rather than supported compatibility behavior.
- `compact_snapshots` limits the union of metric keys to the requested integer
  1..256 bound. The statistical, retention, adapter and receipt helpers are Kujo
  module APIs, not additional CLI commands. Retention returns decisions; it does
  not delete records. `benchmark_compaction` now calls actual compaction.

## Journal recovery and runtime upgrade (2026-09-22 follow-up)

- Requires POSIX Kujo revision `cf785c0a7953717af16b657cda05b85d628144c5`
  or compatible newer runtime; `version`/`doctor` expose `minimum_kujo_revision`.
- `recover --id ID --actor OPERATOR [--dry-run]` is additive. Immutable record and
  creation-event formats remain unchanged. New additive `record.recovered` events
  identify the operator and checksum; existing history entries are preserved.
- Transient intent files use journal version 1.0.0 in `locks/<id>.lock`, max 3 MiB.
  Persistent POSIX lock inodes reside in `guards/`; they must not be removed.
- Failed publication keeps its journal. A same-ID create returns
  `recovery_required`; explicit recovery completes the original intent. Conflicts
  return `recovery_conflict`, malformed/legacy intents fail closed, and a busy
  native guard returns `write_conflict` without waiting or stealing ownership.
- Recovery with no pending journal verifies the existing pair and reports
  `already_complete`; it does not fabricate an event for unjournaled legacy data.
- Listing adds `directory_entries_examined` and `directory_entries_buffered`.
  It buffers at most 1,001 names and returns at most 1,000 candidates per page.
  The cursor still omits `.json`; ordering compares complete filenames, fixing
  prefix-ID continuation while preserving established filename sort order.
