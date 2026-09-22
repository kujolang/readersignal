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

Writers and recovery coordinate through persistent `guards/<id>.guard` POSIX
advisory locks. The OS releases ownership on exit or SIGKILL; never unlink guard
files or infer liveness from their age. `locks/<id>.lock` contains a bounded,
checksummed write-ahead intent before either immutable record or event is
published. Existing record/event files are never overwritten. Export protection
and no-clobber semantics also remain in force.

`recover --id ID --actor OPERATOR` holds the same native guard, validates all
journal fields and existing evidence, publishes only missing exact journal bytes,
appends a `record.recovered` receipt, and clears the intent last. Repeating recovery
is safe; conflicting, malformed or legacy journals fail closed. `--dry-run`
performs validation without publishing or deleting files. An ordinary I/O failure
now retains the intent for recovery instead of deleting a newly published record.

This protocol covers process termination. Atomic file publication does not promise
cross-file durability after power loss: the current runtime does not expose the
parent-directory synchronization contract needed for that guarantee. Keep backups.
Legacy unjournaled orphan records/locks require offline evidence review; the tool
does not reconstruct an original creation event from an unsupported assumption.

Queries process at most 1,000 candidates and retain at most 4 MiB of record source
bytes per page. Warnings count toward the candidate bound. Directory enumeration uses a native bounded heap of at most 1,001 matching names.
It still scans all directory entries on each page (O(N) time), but name-buffer
memory is independent of directory size.
