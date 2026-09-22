# ReaderSignal repository hardening audit

## Repository and scope

- Repository: `kujolang/readersignal`, branch `main`.
- Starting SHA: `389ef125f1a274289b6b3f69810abc8fccf75641` (clean worktree).
- Ending audited implementation SHA: `d7bf0a0d87a5f799ce011a1e742e9afff05212cf`.
  The following documentation-only commit contains this report and its receipts;
  `git log -1 --format=%H -- docs/audits/repository-hardening.md` identifies it
  without embedding a circular self-hash.
- Date: 2026-09-22. Purpose: offline reader measurement, feedback, comparison,
  and evidence-linked editorial learning using immutable JSON records.
- Consumers: humans and automation invoking the CLI; Kujo callers importing
  statistical, privacy, retention and HMAC helpers. No network provider, model,
  MCP service, database, or production subprocess execution exists here.
- Dependencies: Kujo (documented minimum 1.0.1); POSIX shell launcher and Bash
  verification harness. No package-manager runtime dependencies. CI action SHAs
  and Kujo source revision `5059695d14d6726bc17fef55e0b95511624967cf` are pinned.
  Rust toolchain remains `stable`; no transitive vulnerability-clean claim is made.
- Reviewed every tracked implementation, test, fixture, schema, script, workflow,
  instruction, and documentation file. Read relevant Kujo filesystem semantics
  at the CI pin and current source. An independent offline auditor corroborated
  storage, resource and privacy findings. No sibling repository was modified.

## Baseline

`KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo bash scripts/validate.sh`
passed all **39 assertions**, entrypoint checking, JSON parsing, CLI smoke paths,
repository runtime-boundary checks, badge/ignore checks, and whitespace checks.
No existing gate failure was observed. See [baseline receipt](evidence/baseline.txt).
The existing 100,000-snapshot “benchmark” only counted integers and did not call
`compact_snapshots`; its success did not demonstrate compactor correctness or speed.

New behavioral probes against untouched source produced **8 failures and 3 passes**:
global rollup union, malformed snapshot shape, fractional rollup bound, nested
identifier, calendar date, missing flag value, dry-run writes, and state-clobbering
export. See [before-fix receipt](evidence/regression-before.txt). Additional fixes
were supported by source traces and subsequent regression tests, not invented
baseline failure counts.

Measurements used Kujo 1.4.0 on Darwin x86_64, Intel Core i7-9750H @ 2.60 GHz.
Runtime executable SHA-256:
`6178fd8bf108a7be03981c701174814b32e86dcdeabf79fef715d96340b4821f`.
The machine was shared with other work: these are observed timings, not an
isolated throughput guarantee. No baseline memory/build/binary-size measurement
was relevant enough to justify a claim. CI's older pinned runtime was inspected
but not rebuilt locally; local execution claims apply to the stated executable.

## Findings

| ID | Priority | Area | Finding and evidence | Action | Status |
|---|---|---|---|---|---|
| RS-01 | P0 | Integrity/concurrency | `acquire_lock` used check-then-`create_dir`; Kujo uses idempotent `create_dir_all`. Record/event writes enabled replacement. | Exclusive atomic lock files; no-clobber record/event/metadata publication; serialization before locking. | Fixed; eight-process test |
| RS-02 | P1 | Export | `--force` could replace selected state records/history/metadata; non-force replacement raced existence checks. | Canonical parent containment check and atomic no-clobber without force. | Fixed |
| RS-03 | P1 | Resources | Per-snapshot checks did not bound union metric cardinality; helper calls repeated inside compaction's inner loop. | Global 1..256 union bound, numeric overflow checks, direct builtins in hot loop. | Fixed and measured |
| RS-04 | P1 | Privacy | Adapter identifier checks covered only top-level sample keys. | Recursive normalized identifier checks and sample/cohort type validation. | Fixed |
| RS-05 | P1 | Failure semantics | Creation initialized state before validation/dry-run; init/export also accepted dry-run while writing. | Read-only state inspection; writes only after validation; dry-run init/export support. | Fixed |
| RS-06 | P1 | Integrity | `validate` did not inspect audit events; corrupt comparison records were indexed without validation. | Bounded event identity/checksum verification and record validation before compare. | Fixed |
| RS-07 | P1 | Query/output bounds | Filter misses/corrupt files bypassed result limit; warnings grew without bound; stdout exports bypassed output cap. | 1,000-candidate/4 MiB page budgets, resumable cursors, stdout/file 8 MiB cap. | Fixed within RS-14 limit |
| RS-08 | P1 | Health reporting | Truncated validation returned success; doctor hid truncation. | Explicit incomplete errors and cursor continuation. | Fixed |
| RS-09 | P1 | Byte contracts | `len(text)` counts Unicode characters, not UTF-8 bytes. | Byte-accurate serialization limits and export receipts using existing runtime primitives. | Fixed |
| RS-10 | P2 | CLI/config | Version alias discarded flags; missing flag values were accepted; config enforced keys but not schema types. | Preserve alias arguments, reject missing values, enforce config types, catch operational exceptions into the existing envelope. | Fixed |
| RS-11 | P2 | Validation/schema | Invalid calendar dates passed regex; record schema excluded supported legacy version and omitted required contract version. | Calendar checks; align schema with supported 0.1.0/0.2.0 records; reject invalid stored record shape/secret payloads. | Fixed |
| RS-12 | P2 | Verification/DX | Synthetic benchmark, repeated JSON validator startup, leaked test directories, developer-specific launcher default. | Real compaction benchmark; one JSON process; isolated cleanup; PATH-based launcher; focused suites. | Fixed |
| RS-13 | P2 | Crash recovery | Record and audit event are separate atomic publications; kill/power loss can leave an orphan/stale lock. | Detect mismatches; document manual reconciliation; retain review follow-up. | Open design boundary |
| RS-14 | P2 | Directory memory | `sort(list_dir(...))` allocates all names before record budgets. | Bound processing now; evaluate newer bounded runtime enumeration separately. | Open cross-runtime follow-up |
| RS-15 | Needs more evidence | Filesystem authority | Leaf checks do not confine I/O against hostile ancestor replacement. Operator-owned parents/system aliases are existing behavior. | Document trusted-parent assumption; do not silently ban platform aliases or claim descriptor confinement. | Explicit deployment boundary |

Priorities above express engineering impact, not remote exploit severity. There
is no supported remote or multi-tenant attack surface. Local security projections
calibrate caller-data findings accordingly.

## Changes implemented and compatibility

### Persistence, failure handling and export

`src/storage.kujo`, `src/core.kujo`, and `src/common.kujo` now publish locks and
immutable data without replacement. Initialization races re-read the winner's
metadata rather than overwrite it. Serialization and event construction happen
before acquiring the lock, and cleanup errors are no longer silently swallowed.
Existing stale directory locks remain conflicts rather than being removed.
`tests/concurrency_test.kujo` asserts exactly one winner among eight CLI processes,
one matching event/checksum, explicit loser failures, and no remaining lock.
`tests/storage_test.kujo` retains the history-conflict/no-partial-record/retry proof.

Export rejects the selected state tree even through normalized parent aliases.
`--force` remains supported for external files; no-force publication cannot race
into an overwrite. Audit tests cover protected targets, normal exports, safe
replacement, UTF-8 limits, dry runs and history drift. Ordinary event-write failure
rollback remains; crash recovery is not overstated. Core CLI operational exceptions
now produce an error envelope and exit 1, retaining the exception detail.

### Bounded queries and integrity checks

`src/storage.kujo` bounds examined candidates and retained record bytes, returns
`next_cursor` and `scanned`, and avoids unused hashing/repeated state checks in
listing. Public `load_record` still returns its original checksum shape. Invalid
filenames remain cursor-compatible without being used as filesystem paths.
`tests/pagination_test.kujo` covers 1,002 filtered/corrupt records, continuation,
incomplete validation/doctor responses, and six 900,000-character records across
byte-bounded pages. The saved-record validation path checks the creation event;
the legacy fixture now contains a genuinely matching legacy record/event pair.

Consumers must follow `truncated` plus `next_cursor`; an empty filtered page is
not necessarily exhaustion. `validate --after` is additive. A truncated validation
now exits 1 with `validation_incomplete`, correcting the previous false success.
Directory enumeration and concurrent external mutation are separate documented
limits. Doctor checks readability/coverage; use validate for domain/audit integrity.

### Compaction, privacy and numerical correctness

`src/hardening.kujo` enforces the aggregate metric-key union, integer bounds,
object/numeric shapes and finite sums. Its hot loop uses direct dictionary/type
builtins instead of repeatedly calling generic Kujo helpers. Both before and
after measurement scripts assert exact expected views/responses totals. This
keeps input-sensitive validation rather than bypassing it for speed.
The 100,000-item regression now calls real `compact_snapshots`. Large fixtures
are constructed by parsing repeated bounded JSON, avoiding repeated array growth.
Privacy checks recurse into arrays/objects, normalize identifier key spelling,
and reject a supplied cohort count below the declared minimum. Statistical and
retention helpers reject malformed numeric inputs/overflow rather than publish
invalid results. Existing valid fixture behavior is preserved.

### CLI, schema and verification maintenance

`src/args.kujo`, `src/common.kujo`, `src/core.kujo`, and
`schemas/record.schema.json` correct the listed contracts. Tests exercise actual
CLI subprocess exit codes/JSON, not just dispatch calls. The launcher still
honors `KUJO_BIN`, with portable `kujo` PATH lookup as its default. The verification
script keeps tests/domain logic in Kujo; shell only schedules CLI contention and
provides the gate/cleanup wrapper. No dependency was added. The unused private
`parent_dir` and unused import were removed after caller search; other public
helpers and compatibility versions were preserved.

Public function signatures remain compatible; new storage inspection/history
helpers and response fields are additive. Stored record, history and config
formats are unchanged. Record schema now matches implementation. Lock storage
changes from transient directories to exclusive transient files, with old locks
still respected. Environment defaults remain unchanged except the portable
launcher; `READERSIGNAL_TEST_TMP` is an optional test-only scratch-root override.
Strictness increases affect invalid data, audit corruption, incomplete checks,
and unsafe exports. No downstream rewrite or sibling change is required.

## Performance and efficiency

| Measurement | Before | After | Evidence/qualification |
|---|---:|---:|---|
| 1,000-snapshot compaction median, five runs | 28,123,390 µs | 364,619 µs | Same fixture, expected totals, executable and script; shared-machine timing |
| Compaction result cardinality | Union could exceed requested bound | At most requested 1..256 keys | Two distinct one-key snapshots with bound 1 now fail |
| Query candidates/warnings per page | Unbounded for misses/corruption | At most 1,000 | 1,002-item regression |
| Retained record source bytes per page | Up to 1,000 × 1 MiB | At most 4 MiB | Six 900,000-character fixture records paginate 4 + 2 |
| JSON verification process count | 5 | 1 | Five fixture/schema files batched through unchanged validator |
| Assertions in full gate | 39 | 90 | Existing plus CLI/concurrency/resource/boundary regressions |
| Runtime/package dependencies added | — | 0 | Manifest and dependency review |

Raw timing samples are in [before](evidence/compaction-before.json) and
[after](evidence/compaction-after.json). The initial 10,000-item baseline attempt
and a pre-optimization 100,000-item real-compaction probe were stopped because
they were impractically slow; neither is treated as a measured speedup. Final
measurement uses 1,000 items, while correctness separately exercises 100,000.
The improvement is observed; attributing every microsecond to interpreter
function/environment overhead is a code-supported inference, not a profiler result.

No model prompts, tool schemas, conversation replay, or model-token hot path exist
in this repository. The agent instructions remain concise and point to focused
verification/docs. Query payload budgets reduce potential agent-visible output,
but **no tokenizer-based savings claim is made**. Detailed evidence lives in files;
normal tests emit assertion-count receipts. No memory/RSS, binary-size or build-time
improvement is claimed. Wall-clock performance is not a CI threshold on shared
hosts; deterministic cardinality, bytes, correctness and process behavior are gates.

## Security review

Reviewed CLI/config/payload trust boundaries, ID-to-path flow, symlink checks,
filesystem publication, JSON parsing, state version compatibility, fixture privacy,
HMAC verification, export authority, temporary files and concurrent writes.
No production shell interpolation, HTTP/SSRF, model execution or credential
loading exists. The concrete fixes and remaining constraints are recorded above.

The security plugin capability preflight returned ready; Daybreak returned granted
(Blue). Its managed report service failed at startup with a Python compatibility
error. Offline review continued. The local canonical JSON artifacts were finalized
successfully with the plugin's finalizer under `.tmp/security/`, including generated
`report.md`. That projection marks coverage partial because filesystem/recovery
follow-ups remain; it does not imply unread source or an external certification.
Its baseline findings are preserved, while this report describes final remediation.

## Cross-repository follow-ups

**Kujo runtime:** the CI-pinned filesystem implementation has `list_dir` but not
`list_dir_page`. Current inspected Kujo source includes a newer paged primitive.
Evaluate its bounded-memory, deterministic cursor and compatibility behavior before
updating ReaderSignal's runtime pin/minimum and adopting it. This would address
RS-14; current correctness fixes do not require it. Do not silently switch an
established runtime contract or modify Kujo from this repository.

Related SignalBox directory-enumeration work already exists for Dossier
(`cap_a358124b-cb89-4cf7-a5ac-ae4c665125f1`,
`sig_806c90dc-02bb-4569-8014-d08e1b7d7525`); this pass avoids duplicating that
runtime-wide observation. Other sibling storage implementations were inspected
only for contract context; no unverified vulnerability was assigned to them.

## Remaining work

- **P0/P1:** no known unresolved in-scope regression or confirmed fix left undone.
- **P2:** RS-13 deliberate crash reconciliation/journaling; RS-14 bounded directory
  enumeration after runtime compatibility evidence. These require design decisions,
  not timeout increases or silent repair. ReaderSignal-specific crash recovery is
  retained in SignalBox; see the consolidation receipt below.
- **Needs more evidence:** descriptor-confined reads/writes and hostile ancestor
  replacement protections would require a separately specified trust boundary and
  runtime support. No adversarial shared-directory safety claim is made.
- **P3 / not worth changing:** wholesale reformatting of compact legacy domain
  helpers, framework extraction across siblings, new caching/index formats, or
  replacing standard cryptography/JSON functionality. No cosmetic churn was done.

## Verification receipt

All commands run from the repository root unless stated. `K` below denotes the
exact runtime path `/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo`.

| Exact command | Result |
|---|---|
| `KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo bash scripts/validate.sh` before edits | Pass, 39 assertions |
| `$K run tests/audit_test.kujo` on baseline | Expected failure: 8 failed / 3 passed; retained evidence |
| `$K run scripts/benchmark.kujo` in `.tmp/baseline` archived from starting SHA | Pass, five 1,000-item samples |
| `$K run scripts/benchmark.kujo` on final compactor | Pass, five 1,000-item samples |
| `$K check readersignal.kujo` | Pass |
| `$K check tests/pagination_test.kujo` | Pass |
| `$K run tests/storage_test.kujo` | Pass |
| `$K run tests/hardening_test.kujo` | Pass, includes actual 100,000-item compaction |
| `$K run tests/audit_test.kujo` | Pass, 24 assertions in final suite |
| `$K run tests/pagination_test.kujo` | Pass, 10 assertions in final suite |
| `$K run tests/concurrency_test.kujo -- $K` | Pass, 14 assertions / eight contending processes |
| `$K run tests/cli_test.kujo -- $K` | Pass, 3 actual-CLI assertions |
| `/usr/bin/time -p env KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo bash scripts/validate.sh` | Pass, 90 assertions; 21.66 s wall / 16.13 s user / 4.63 s sys |
| `git diff --check` | Pass |
| `python3 /Users/robertdevore/.codex/plugins/cache/openai-curated-remote/codex-security/0.1.24/scripts/finalize_scan_contract.py --scan-dir .tmp/security --source-root .tmp/baseline` | Pass; local generated security report |

The gate also executes the baseline test/security/domain suites, batches every
fixture/schema through `scripts/validate_json.kujo`, runs help/version/doctor smoke
commands, checks runtime-language boundaries and local artifact exclusions, and
checks the Git diff. There is no separate application build, formatter, network
integration suite, or hosted E2E deployment to run. Its real CLI/concurrency paths
provide local E2E coverage. New tests were not weakened to hide failures: a
Unicode fixture was corrected to use supported whole-dictionary assignment, and
a large numeric literal was supplied through JSON because Kujo lexical syntax
does not accept scientific notation directly.

Final logs: [verification](evidence/verification.txt),
[timing/stderr](evidence/verification-timing.txt),
[final hardening suite](evidence/hardening-final.txt).

## Durable record

Strata consolidation stores the repository handoff/current-state timeline with
commit and report provenance, avoiding duplicate implementation prose. SignalBox
only admits the unresolved ReaderSignal crash-recovery concern; completed fixes
and ordinary verification are excluded. Exact saved IDs and retrieval results
are recorded in `evidence/consolidation.md` after persistence.
