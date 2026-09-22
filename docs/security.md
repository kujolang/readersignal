# Security and authority

ReaderSignal is an offline OBSERVE/PROPOSE tool. It performs no network requests,
provider scraping, publication effects, or shell execution in production. Its
optional HMAC helper authenticates supplied PressWire receipts with an explicit
shared key; it does not acquire credentials or publish anything.

State is operator-controlled, not a multi-tenant authorization boundary. Use
trusted parent directories and do not allow another process to replace them while
ReaderSignal is running. State roots, managed directories, records, inputs,
artifacts, and existing export targets reject leaf symlinks. Ancestors are trusted
and may include platform aliases such as macOS `/tmp`; current checks do not
provide directory-descriptor confinement against hostile ancestor replacement.

IDs reject traversal. Inputs and records are limited to 1 MiB **UTF-8 bytes**,
artifacts to 64 MiB, config/metadata/audit events to 64 KiB, and export envelopes
to 8 MiB. Secret-shaped payload keys and nested adapter identifiers are rejected.
Adapter conformance validates supplied aggregates, not the truth of measurements.

Record locks use exclusive atomic file publication. Record and history writes
never replace existing targets. Exports cannot target the selected state tree,
even with `--force` or through a canonical parent alias. Non-force exports use
atomic no-clobber publication; force only replaces ordinary external exports.
Do not point exports at a different, unrelated tool's state: ReaderSignal cannot
identify all other applications' storage.

Record and event publication are individually atomic, **not one crash-atomic
transaction**. Ordinary event write failures roll back the new record. A killed
writer or power loss can leave a record without an event and a stale lock.
`validate` checks event identity and checksums and refuses incomplete coverage.
Never automatically delete locks by age: first stop writers, preserve a copy of
state, inspect the record/event pair, and reconcile from trusted evidence. There
is no automatic recovery or full-durability claim.

Queries process at most 1,000 candidates and retain at most 4 MiB of record source
bytes per page. Warnings count toward the candidate bound. Directory names are
still enumerated and sorted in memory; huge-directory memory is not constant.
