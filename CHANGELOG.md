# Changelog

## 0.3.0 - 2026-09-26

- Added journal-backed crash recovery and read-only recovery diagnostics, with regression coverage at eight interruption boundaries.
- Added bounded, no-clobber `backup` and `restore` commands that preserve exact original record and creation-event evidence.
- Persisted initialization, intent, record, history, and cleanup ordering with directory sync barriers; uncertain outcomes remain explicit.
- Hardened immutable publication, per-record guards, confined state I/O, export containment, audit validation, configuration, privacy checks, and failure envelopes.
- Bounded directory enumeration, candidate reads, page bytes, output, and compaction metric cardinality; added resumable cursors and completeness reporting.
- Preserved 0.1.0 and 0.2.0 record reads under contract 1.0.0; new records identify tool version 0.3.0.
- Require POSIX Kujo 1.5.0 at revision `d501c2c46c51718ee10c4434f6cf9750bbd81453` or a compatible newer build. The version number alone does not guarantee the required preview APIs.


- Standardized README badge ordering and repository-local artifact ignores.
- Kept Loop Engineering evidence available locally while removing it from published source.

## 0.2.0 - 2026-08-14

- Preserved validation compatibility with immutable 0.1.0 records while emitting 0.2.0 records.
- Prevented audit-history conflicts from leaving partial records and added clean-retry regression coverage.
- Enforced bounded numeric metric maps and non-empty evidence sets alongside stronger state, timestamp, actor, pagination, and immutable-record validation.
- Added privacy-bounded domain contracts, compatible-window comparisons, immutable storage, structured failures, CI, and expanded verification.

## 0.1.0 - 2026-08-14

- Initial Kujo-native release with working local records, validation, contracts, fixtures, and safety boundaries.
