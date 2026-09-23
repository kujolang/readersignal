# Process-crash recovery and bounded directory enumeration

This follow-up closes the original audit's RS-13 process-crash recovery gap for
journaled writes and RS-14 directory-name memory gap. It starts at commit
`4a6fc81958d72a337b72e38ea7fd73356fb3a8ad`. The ending implementation SHA is `ac4ad051d7fb865eb8ee26aa5a607a2242a371e0`;
the subsequent documentation-only commit carries these receipts. Original audit evidence remains
in `docs/audits/`; follow-up receipts are in `docs/audits/evidence/recovery/`.

## Runtime and upgrade

Use POSIX Kujo 1.4.0 revision
`cf785c0a7953717af16b657cda05b85d628144c5` or a compatible newer build. The
version label alone does not establish availability of the preview `file_lock`,
`file_unlock` and `list_dir_page` APIs. CI pins this revision and builds with
`--locked`; the local validation gate probes the needed native capabilities.
The selected revision was verified present in Kujo's remote branch ancestry; no
sibling files were modified. The source implementation and the installed binary
were both inspected/exercised. No claim of locally rebuilding that exact runtime
revision is made. Pinned-source CI run 35796716113 subsequently passed.
The [completion review](audits/completion.md) records the current verification
and remaining upstream durability requirements.

Stop older writers before upgrading. Existing record, metadata, configuration and
creation-event formats remain valid. Run `readersignal init --state PATH` to add
the new `guards/` directory to old state without replacing metadata. Read-only
queries still work on old state. New guards/intent files are additive storage
artifacts; no record migration or new service/dependency is required.

Native Windows mutation is not supported by these POSIX locking primitives;
use a POSIX environment such as the Linux CI environment. Guard files are
private user-owned regular files, as enforced by Kujo. Keep state parents trusted.

## Write protocol

1. Validate and serialize the record, enforce its byte limit, and derive the exact
   creation event and checksum.
2. Acquire a nonblocking OS advisory lock on `guards/<id>.guard`. A conflicting
   writer/recoverer gets `write_conflict`; age never proves abandonment.
3. Check that no record, creation event or pending/legacy intent already exists.
4. Atomically publish a no-clobber journal at `locks/<id>.lock` containing exact
   serialized record/event bytes and their binding checksum.
5. Publish the record, then its creation event, without replacement.
6. Remove the journal only after both publications succeed, then unlock the guard.

The journal is the old lock pathname, so the preceding no-clobber implementation
also refuses pending intents. Guard inodes persist (one per record ID) and must
**never be unlinked while writers can run**. Lock ownership is held by the OS,
not by the existence or timestamp of the file. Process death releases ownership;
a crash before journal publication leaves no transaction requiring repair.

Failures after journal publication retain the intent. This deliberately replaces
the old best-effort rollback with replayable evidence. A same-ID retry does not
silently finish a previous operation: it returns `recovery_required`. Any atomic
write temporary files left by a killed process are not evidence and are ignored
by record enumeration; cleanup should happen offline, never by deleting guards.

The journal format is documented in `schemas/write-intent.schema.json`. Total
journal size is capped at 3 MiB, embedded record bytes at 1 MiB and event bytes at
64 KiB. A journal is not a signed authorization token: state remains controlled
by the operator, and checksums detect inconsistencies rather than a malicious
owner who can replace all state files.

## Recovery command

```bash
readersignal recover --state .readersignal --id snapshot-example --actor operator --dry-run --json
readersignal recover --state .readersignal --id snapshot-example --actor operator --json
```

Recovery acquires the same OS lock. It validates the journal version, safe ID,
serialized JSON shapes, sizes, record digest, timestamp, and event-to-record
identity. It derives filesystem paths internally; journal contents cannot provide
arbitrary destination paths. Existing record/event bytes must match exactly;
regular-file checks reject directories, symlinks and oversized objects.

After preflight, only missing files are published. Recovery then appends one
deterministically named `record.recovered` event with the recovering actor, time
and record digest, and removes the journal last. If recovery itself dies, the same
intent can be replayed again. An existing matching recovery receipt is preserved,
including its original actor/time. A mismatched receipt is not overwritten.

`--dry-run` performs the same evidence checks and reports which files are missing
without creating, publishing or removing files. It requires the guard created by
the original writer to exist. An already-completed pair is validated and reported
as `already_complete`; recovery never synthesizes evidence for a missing journal.
The stable JSON envelope and success/operational/usage exit classes remain intact.

Use `readersignal recovery-status --state PATH --id ID --json` for read-only
evidence classification, including legacy state without guards. It emits a compact
observation without copying sensitive evidence or creating files; zero exit means
inspection succeeded, not that state is healthy. See the
[offline review procedure](audits/completion.md#legacy-review-procedure).

Legacy directory/text locks contain insufficient evidence to reconstruct an
original write. They fail closed and require offline review after all writers
have stopped. This is an information limit, not a reason to fabricate historical
creation events or steal a possibly live legacy lock. `--force` does not bypass
any recovery check.

## Directory paging

`list_records` calls Kujo's native `list_dir_page` with a 1,000-entry page and
`.json` suffix. The native implementation scans directory entries and retains
only the smallest 1,001 eligible names in a bounded heap. Final sorting is limited
to that heap. Record-byte, candidate-count, warning-count and result-count budgets
continue to apply. There is no fallback to unbounded `list_dir`.

- Name-buffer capacity: **at most 1,001**, independent of directory cardinality.
- Filesystem enumeration: still **O(N) per page**; no constant-time claim.
- Candidate reads: at most 1,000; retained record source bytes: at most 4 MiB.
- New receipts: `directory_entries_examined`, `directory_entries_buffered`.
- Cursor: the existing ID-style value without `.json`, compared as a complete
  filename internally. This also fixes continuation when one ID prefixes another:
  `snapshot-a-child.json` sorts before `snapshot-a.json`, and neither is skipped.

Directory contents are not a snapshot under concurrent external edits. The
operator-controlled/trusted-parent deployment boundary is unchanged.

## Verification and durable limits

Baseline gate: **90 passing assertions**. Final gate: **129 passing assertions**,
including native capability probing, all prior suites and 38 recovery assertions.
The 1,002-record pagination fixture proves only 1,001 names are buffered and
1,000 candidates examined per page, while cursor continuation visits the remainder.

The recovery worker calls production `begin_write`, publishes exact intent bytes
to deterministic phase boundaries, and receives a real SIGKILL while owning the
OS guard. Tests cover death after intent, record and event publication; actual
CLI replay; read-only preview; existing receipt replay; active-writer exclusion;
conflicting/corrupt/legacy intents; checksum tampering; dangling target/intent
symlinks; safe IDs; actor requirements; idempotence; and prefix-ID pagination.
No production fault-injection environment variable, artificial sleep, or timeout
increase is used. Normal eight-writer concurrency and actual 100,000-snapshot
compaction remain in the full gate.

Commands:

```bash
KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo bash scripts/validate.sh
/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo run tests/recovery_test.kujo -- /Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo
git diff --check
```

See [baseline](audits/evidence/recovery/baseline.txt),
[final verification](audits/evidence/recovery/verification.txt) and
[timing](audits/evidence/recovery/timing.txt). These are local Kujo 1.4.0 results;
the code-required runtime APIs were probed directly. No runtime-speed or RSS
improvement is asserted for directory paging; the deterministic buffer bound is
the regression guarantee.

Process-crash recovery does **not** establish arbitrary power-loss durability.
The runtime's individually atomic file writes do not expose the parent-directory
synchronization contract required to guarantee cross-file ordering through power
failure. This implementation makes no such guarantee and does not modify Kujo to
invent one. Backups, trusted parent directories, and explicit review of legacy
unjournaled damage remain operational requirements.
