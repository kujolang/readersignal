# ReaderSignal remaining-work review — 2026-09-23

Repository: `kujolang/readersignal`, branch `main`. Starting SHA:
`b843c026912d2562677ae17d3b831044f8445a87`. Ending implementation SHA:
`bf3883208c642b2ea603a2f3e05ffc59b6b4c99f`. ReaderSignal keeps local, privacy-bounded measurement and
learning records; Kujo is its only application runtime. No sibling was modified.

## Findings and disposition

| ID | Priority | Area | Evidence / finding | Action | Status |
|---|---|---|---|---|---|
| RS-15 | P2 | Bounded I/O | Path size checks followed by unrestricted reads could read a growing/replaced file beyond the application limit | Use native opened-handle bounded reads for metadata, records, journals, history, input and config; count bytes actually read for page budgets | Implemented |
| RS-16 | P2 | Publication | Managed atomic writes reopened ambient paths after validation | Use `write_file_atomic_beneath` from the trusted state root for metadata, intent, record and both event types | Implemented; root remains trusted |
| RS-17 | P2 | Legacy recovery | Legacy text/directory locks cannot be inspected through recover without initialized guards | Add read-only `recovery-status --id` with compact evidence classification, no initialization, lock theft or history fabrication | Implemented |
| RS-18 | P2 | Runtime evidence | Earlier report lacked evidence of a pinned-source CI run | GitHub validate run 35796716113 succeeded for the preceding pushed revision; capability gate now also exercises bounded read/confined write | Prior runtime uncertainty resolved; new CI run tracked separately |
| RS-13 | P2 | Crash recovery | Intent/record/event SIGKILL boundaries already covered by production recovery tests | Preserve the existing replay protocol; add legacy and conflicting-receipt inspection coverage | Completed for process crashes |
| RS-14 | P2 | Enumeration | Native heap retains at most 1,001 names; scan remains O(N) | Preserve filename cursor semantics and existing pagination regression gate | Completed for bounded memory; no indexed-scan claim |
| RS-19 | P2 | Durability | Both Kujo atomic writers sync temporary file contents but do not sync the published parent directory | Specify upstream requirements below; retain explicit guarantee boundary | Blocked by runtime durability contract |

## Implemented changes and compatibility

`src/storage.kujo` now performs reads through `read_file_beneath` and publications
through `write_file_atomic_beneath`. These APIs walk managed components relative
to retained directory handles and reject symlinks. Reads enforce their byte bounds
on the opened file, including growth after a preliminary size check. Preliminary
checks stay in place to preserve existing error codes. A failed bounded record
read returns `record_read_failed`, including a per-record warning in enumeration.
The page byte budget uses the bytes actually returned, not an earlier stat.

`src/core.kujo` also bounds input and config reads on opened handles. Their chosen
parent directory is trusted; the leaf must remain a regular non-symlink file.
Managed formats, checksums, exact serialized bytes, no-clobber behavior, journal
ordering and locks remain compatible. No new dependency, runtime revision,
environment variable, config option or existing schema is required.

`src/profile.kujo` exposes additive command `recovery-status`. Its status receipt
is an observation, never an authorization to repair or delete. A successful
inspection exits zero even when its `status` identifies damaged evidence; it does
not replace `validate` or `doctor` as a health gate. Invalid IDs/unsafe state fail.
The receipt contains no record, event or journal bodies. Detailed evidence stays
in the original state. Tests and the native capability probe are part of CI.

## Legacy review procedure

1. Use `readersignal recovery-status --state PATH --id ID --json`. It works without
   an actor, without guards, and without creating an absent state directory.
2. For `replayable`, use the documented `recover --dry-run` then `recover` after
   initialization if required. Recovery obtains the native guard and repeats all
   checks. Inspection can observe a live writer and does not prove abandonment.
3. For `complete`, record and creation-event identity/digest agree. This is not a
   domain-schema validation claim; run `validate` for that.
4. For `legacy_or_invalid_intent`, `conflicting_evidence` or `evidence_required`,
   stop all old and new writers and preserve a backup of the entire state before
   manual review. Recover original exact record/event/journal bytes only from
   trusted backup evidence. Do not generate an alleged original creation event
   from an orphan record. Preserve the damaged copy for comparison; validate a
   separately restored state before selecting it with `--state`.
5. If original evidence does not exist, historical integrity cannot be recovered
   by software. Keep the damaged evidence and start a separate state for new
   measurements. No age threshold or `--force` bypass proves legacy lock safety.

## Remaining scope and upstream contract

- **P0/P1:** no known introduced regression or unfinished confirmed in-scope fix.
- **P2, cross-repository:** Kujo must expose durable directory publication and
  deletion with explicit `published` versus `durability_confirmed` results.
  ReaderSignal needs to persist newly created state/managed directory entries,
  persist the intent entry before targets, persist targets and recovery receipt
  before clearing the intent, and durably clear it last. Sync failure after
  publication must retain replayable intent and report an uncertain outcome,
  never pretend publication did not happen. Test failure at each boundary on
  supported filesystems before expanding the guarantee. Hardware/filesystem
  guarantees still need qualification. Current source inspected at Kujo
  `df2858643e3c9ca4f7e730344c15fae13da2a1cc`.
- Kujo's newer private-spool API has a directory-sync receipt, but it is not a
  complete durable-directory lifecycle API. Adapting spools as dummy sync markers
  would add artifacts and ambiguous failures; it is not a justified workaround.
- **Needs a new trust-boundary design:** the state root/ancestors remain trusted.
  Guard acquisition, initialization, enumeration and journal deletion do not share
  a single retained root capability across the transaction. Confined individual
  reads/writes strengthen managed paths but cannot establish hostile-owner or
  multi-tenant safety. No such claim is made. Runtime handle-based locking,
  directory creation/deletion and transaction-root lifetime APIs are prerequisites.
- **Not worth changing without evidence:** an index or shard format solely to
  avoid the O(N) directory scan. It adds migration, concurrent-update and crash
  consistency contracts; current memory is bounded. The newer native enumeration
  API also sorts suffix-stripped IDs rather than complete filenames and caps scan
  cardinality; adopting it casually changes pagination and supported state size.
- **Information limit:** absent legacy history cannot be reconstructed. Inspection
  and the offline restore procedure complete the safe repository-side work.
- **P3:** cosmetic rewrites and cross-repository framework extraction remain out
  of scope.

The runtime durability follow-up is already captured in SignalBox as
`cap_17d7080c-e46e-45e7-ac6e-4dbcf7997f51`, signal
`sig_7eaefae1-7b50-4616-afe0-4727ff0fa4c5` (Kujo). No duplicate was created.
No external consumer needs a change to use this ReaderSignal update. Expanding
power-loss or hostile-root guarantees requires the upstream contracts above.

## Verification and measured impact

Baseline: **129 passing assertions**. Final: **152 passing assertions**, including
23 new checks in `tests/recovery_status_test.kujo`. Full gate includes actual
SIGKILL recovery, eight-writer contention, pagination, 100,000-item compaction,
CLI/security/domain suites, syntax checks, fixture/schema parsing and smoke tests.

Opened-file limits: config/metadata/history **64 KiB**, records/input **1 MiB**,
intent **3 MiB**. Existing retained page budget remains **4 MiB**, with at most
**1,001 buffered names** and **1,000 candidate reads**. These are deterministic
bounds, not latency/RSS improvements. No performance percentage or token estimate
is claimed. Dependency and persisted format counts are unchanged.

Exact commands, run from ReaderSignal unless noted:

- `KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo bash scripts/validate.sh` — baseline and intermediate passes.
- `/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo check readersignal.kujo` — pass.
- `/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo run tests/recovery_status_test.kujo` — pass, 23 assertions.
- `/usr/bin/time -p env KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo bash scripts/validate.sh` — final gate; logs below.
- `git diff --check` — pass.
- `gh run list -L 3` — confirmed prior pinned-runtime CI success.

Evidence: [baseline](evidence/completion/baseline.txt),
[verification](evidence/completion/verification.txt),
[timing](evidence/completion/timing.txt). A mistaken scratch command was initially
run from SignalBox's directory and failed before editing any file; the corrected
ReaderSignal invocation passed. No test was disabled or assertion weakened.

The final local gate took 22.19 s wall / 15.37 s user / 4.15 s sys on the shared
host; this is a verification receipt, not a benchmark speedup. A post-gate bare
filename probe exposed Kujo `dirname("kujo.toml") == ""`; the reader now maps
that parent to `.`. Two input/config regressions and the full gate passed after
the fix.
