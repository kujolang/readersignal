> Latest verification and remaining evidence requirement: [2026-09-25 follow-up](durability-follow-up.md).

# Durable publication and trusted evidence restore

Repository: `kujolang/readersignal`, branch `main`. Starting SHA:
`6d847ff36e5a300cb2f47ee073bcbebf3e5cd70a`. This pass implements the previously
blocked directory durability mechanism in Kujo and adopts it here. The user
explicitly authorized this cross-repository follow-up. Both repositories started
clean. Ending implementation SHA:
`0b283c75cd8be5037aa5205bbf6e131e31062be7` (core implementation
`b83e6d27c208d7a9dd14948c5014fdb0b2156143`); following documentation commits
carry verification receipts.

## Findings and changes

| ID | Priority | Finding / evidence | Action | Status |
|---|---|---|---|---|
| RS-19 | P2 | File-content sync did not persist parent-directory publications | Added Kujo directory barrier and ordered ReaderSignal initialization/journal/record/history/cleanup barriers | Implemented |
| RS-20 | P2 | Safe legacy reconstruction needed original exact evidence from a backup | Added bounded, no-clobber `backup` and journaled `restore` commands with read-only previews | Implemented; no live restoration requested |
| RS-21 | P2 | Failure after unlink could incorrectly claim intent was retained | Return unconfirmed durability with phase/intent-cleared receipt for barrier failures; document idempotent recovery after cleanup | Implemented |

Files: `src/storage.kujo` implements ordered barriers and evidence operations;
`src/core.kujo` exposes commands through the existing envelope/export protections;
`src/profile.kujo`, the capability probe and pinned CI revision enforce the new
runtime dependency. `tests/recovery_worker.kujo` / `tests/recovery_test.kujo` add
crash boundaries; `tests/backup_test.kujo` adds round-trip and rejection coverage.
`schemas/backup.schema.json` documents the additive checkpoint format.

## Runtime requirement and publication protocol

Use POSIX Kujo 1.5.0 at revision
`d501c2c46c51718ee10c4434f6cf9750bbd81453` or a compatible newer build. CI builds
that exact source with `--locked`. `sync_directory_beneath(root, relative)` is a
filesystem-write capability operation; it returns true only after the OS confirms
sync of the opened directory. It rejects symlinks below its trusted root. It is
a standalone barrier: failure does not undo a preceding write or delete. No
previous Kujo builtin contract changed and no dependency was added.

ReaderSignal now orders writes as follows:

1. During initialization, sync each parent after creating/checking each state-path
   component; create managed children and sync state after metadata and directory
   initialization. A concurrent metadata winner still requires this final barrier.
2. Hold the existing per-ID OS guard, atomically write and sync journal contents,
   then sync `locks/` before publishing any record.
3. Atomically publish missing record contents and sync `records/`.
4. Atomically publish the creation event and optional recovery receipt, then sync
   `history/`. Existing matching targets are retained, with their directory
   barrier repeated on recovery.
5. Unlink the journal last, then sync `locks/` before acknowledging completion.

Successful publication/recovery receipts include `durability_confirmed: true`.
A failed barrier reports `durability_unconfirmed` with `phase` (intent, record,
history, cleanup) and `intent_cleared`. Before cleanup, the journal is retained.
After cleanup, it may already be absent; `recover` validates the completed pair,
repeats directory barriers and reports `already_complete`. Other I/O exceptions
also explicitly warn that namespace changes may already have happened. Do not
blindly repeat a non-idempotent create after an uncertain outcome.

These guarantees assume the OS, filesystem and storage hardware honor successful
file/directory sync. SIGKILL tests do not simulate controller cache loss or power
cuts. No arbitrary-hardware, network-filesystem or hostile-root guarantee is made.
The existing local-owner/trusted-parent deployment boundary remains in force.

## Backup and restore workflow

```bash
readersignal backup --state .readersignal --id snapshot-example --output /trusted-backups/snapshot-example.json --dry-run --json
readersignal backup --state .readersignal --id snapshot-example --output /trusted-backups/snapshot-example.json --json
readersignal restore --state .readersignal-restored --id snapshot-example --input /trusted-backups/snapshot-example.json --actor operator --dry-run --json
readersignal restore --state .readersignal-restored --id snapshot-example --input /trusted-backups/snapshot-example.json --actor operator --json
readersignal validate --state .readersignal-restored --id snapshot-example --json
```

The existing output parent must exist and be trusted. A checkpoint preserves the
exact original record and creation-event bytes and their binding digest. Backup
requires both to validate and rejects pending/legacy intents. It requires an
explicit output outside managed state, refuses `--force`, atomically publishes
without replacement, and syncs the output parent. On a post-publication sync
failure, `backup_uncertain` includes `published: true`; preserve and inspect that
file rather than overwriting it. Retry backup to a fresh output name after the
filesystem problem is resolved. Previews publish nothing.

Restore reads at most 4 MiB, validates the envelope, selected ID, format, embedded
sizes/digests and record/event identity before initializing a destination. The
embedded journal stays bounded to 3 MiB, original record to 1 MiB and event to
64 KiB. It never re-serializes original evidence. It requires a printable actor,
refuses any existing record/event/intent for that ID, and uses the ordinary
journal/guard/durability protocol. It appends `record.recovered` with the restoring
actor without changing the original creation actor/time. If interrupted, use
`recover` on the destination ID. Repeating `restore` itself refuses replacement;
`recover` is the idempotent continuation. `--force` grants no restore bypass.

A checkpoint is **one record and its creation event**, not a backup of all state,
all recovery receipts, external artifact attachments or metadata. Copy required
external attachments separately through a trusted backup process. For multiple
records, select IDs through paginated `report` and create a checkpoint per ID;
no unbounded all-state buffering is introduced. Run `validate` after restoration
for domain/configuration/attachment checks as well as evidence checks.

Checksum consistency is not proof of trusted origin. Supply a checkpoint from a
trusted location; do not treat arbitrary downloaded JSON as historical authority.
Preserve damaged original state. Restore into a separate state and select it with
`--state` only after validation. Existing legacy record/event directories from a
trusted offline backup can first be inspected with `recovery-status`, then used
as the source of `backup` when the pair is complete. Incomplete backups are
rejected; missing evidence is never synthesized.

The user confirmed that no live legacy restoration is needed. The commands were
verified on isolated fixtures; no live data restoration is part of this task.
A future restoration would require trusted original evidence, but this is not
an outstanding repository-hardening blocker.

## Compatibility, efficiency and security

Existing record, creation-event, config and environment formats are unchanged.
The backup envelope and two CLI commands are additive. New directory-sync
requirements raise the pinned runtime revision; unsupported builds fail the
capability gate. Upgrading old state still uses `init`. Stop older writers before
upgrading, and keep guard inodes intact.

The additional fsync operations deliberately add I/O. No speedup or hardware
power-loss experiment is claimed. Memory remains bounded per record/checkpoint;
record enumeration still buffers at most 1,001 names. No new application
dependency or full-directory backup buffering was introduced. Original authority,
privacy and symlink boundaries are preserved; backup files contain original data
and need the same operator-controlled confidentiality as source state.

## Verification

Baseline ReaderSignal gate: 152 assertions passed. Final gate: 218 assertions
passed. Results and exact
commands are recorded in `evidence/durability/`. Recovery now exercises SIGKILL
after intent, record, record-directory sync, event, history-directory sync,
recovery-receipt sync, intent unlink and final cleanup sync. These tests use the
real guard and filesystem; there is no production fault environment or sleep.
Backup tests cover exact/noncanonical serialization, digest/ID mismatch, actor,
traversal, preview purity, source corruption, legacy locks, symlinks, no-clobber,
state exclusion and audit validation.

Kujo checks passed: 912 library tests (7 existing ignored), 90 security-boundary
tests, 52 CLI/readme/diagnostic contract tests and formatting. A unit-injected
sync error verifies the primitive cannot return success after a failed barrier.
Native evidence is committed in Kujo `docs/audits/directory-durability.md`.

## Remaining work

- No known unfinished implementation for the requested repository durability and
  backup/restore mechanisms; no known introduced regression.
- No live legacy restoration is required, as explicitly confirmed by the user.
- Physical power-cut validation on a particular deployment's storage, if required,
  is an operational certification task. The implementation is sync-contract
  based, not a claim to survive hardware violating that contract.
- Hostile-root/multi-tenant protection remains outside the documented trust
  boundary; directory barriers do not change authority or provide a sandbox.
- Existing Kujo SignalBox durability capture is addressed by the new primitive;
  no completed-work capture or disposition was created.

### Executed commands

From ReaderSignal (runtime paths are literal):

- `KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo bash scripts/validate.sh` before changes: 152 assertions passed.
- `KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/debug/kujo bash scripts/validate.sh`: 218 assertions passed on final implementation.
- `../kujo/target/debug/kujo run tests/backup_test.kujo`: 21 passed.
- `../kujo/target/debug/kujo run tests/recovery_test.kujo -- /Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/debug/kujo`: 78 passed.
- `../kujo/target/debug/kujo run tests/cli_test.kujo -- /Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/debug/kujo`: 8 passed.
- `../kujo/target/debug/kujo check readersignal.kujo`: passed.
- `git diff --check`: passed.

Initial debug gate invocation before the new runtime binary existed correctly
rejected the missing `sync_directory_beneath` capability. The gate passed after
building the binary. Tests were not weakened to hide this compatibility failure.
The fixture path in the new backup test was corrected to the existing
`fixtures/core.json` before its first execution.

### Linux portability correction

Kujo CI run 35912612913 exposed that its traversal capability may use a Linux
`O_PATH` descriptor, which cannot be fsynced. ReaderSignal's first pinned Linux
run 35915557080 also failed at the new barrier. Kujo fix
`d501c2c46c51718ee10c4434f6cf9750bbd81453` reopens `.` for reading relative to
the retained directory, without reopening an ambient path; ReaderSignal now pins
that correction. The existing nested-directory regression stays enabled.
The macOS release gate at the earlier revision passed 218 checks in 26.70 s;
this is not evidence of Linux correctness. The corrected source built successfully
with `cargo build --release --locked`. The corrected macOS release runtime passed
the same full gate: 218 assertions, 21.28 s wall, 10.83 s user, 2.95 s system.
These timings record test execution; they are not a controlled performance
comparison. No speedup is claimed.

ReaderSignal Linux CI [35916802587](https://github.com/kujolang/readersignal/actions/runs/35916802587)
passed, independently building the pinned corrected runtime. Kujo Linux CI
35916711263 passed formatting, clippy, minimal smoke and VM/interpreter parity;
the broader release job then identified stale generated source-line references.
The authoritative generators refreshed only those inventories and their date.
Detailed native verification is recorded in Kujo's directory-durability audit.

Final local command:
`/usr/bin/time -p env KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo bash scripts/validate.sh`.
Output: `evidence/durability/release-verification.txt`; timing:
`evidence/durability/release-timing.txt`. The earlier macOS run is preserved as
`release-before-linux-fix.txt` and `timing-before-linux-fix.txt`.

Native inventory follow-up committed and pushed as
`b811f24e868b2847917ffbd3259f486a6e18c4ab`. Its isolated generated-artifact
contract suite passed all three tests. ReaderSignal retains the already-verified
`d501c2c` runtime pin because the follow-up changes only generated inventories
and audit evidence, not executable source. Native broad CI rerun:
https://github.com/kujolang/kujo/actions/runs/35919303004.

The ReaderSignal working tree is dedicated to this task. Concurrent unrelated
upgrade/release edits appeared in the Kujo shared checkout after implementation;
they were preserved and excluded from these commits. Inventory verification used
an isolated checkout so those edits could not contaminate its baseline.
