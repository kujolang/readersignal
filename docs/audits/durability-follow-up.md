# Durability completion follow-up — 2026-09-25

ReaderSignal starting revision: `f147f7bd7293500d83d88adeb7cbf89f39e6e3a9`.
Kujo starting revision: `136cea468c8c17c0c71ed4da5a9bd41b05759163`.
Both working trees were clean when this follow-up began.

## Revalidated blockers

The previously pending Kujo run 35919303004 completed with failure. Its failed
job 107381834474 reached `stdlib_reference_contract` and found the new
`sync_directory_beneath` inventory arity was `2` where centralized metadata
requires `exact 2`. Corrected the documentation, without altering the builtin,
metadata or test. Commit: `fe1de37`.

Subsequent Kujo main development introduced two stale source locations in the
unsafe inventory, independently confirmed by job 107633876473 of run
35999273636. Regenerated the Markdown and CSV with the authoritative script;
only source locations and generation date changed. Commit: `8c27526`.
Both commits are pushed. ReaderSignal's runtime pin remains unchanged because
neither correction changes executable behavior.

## Verification

- `cargo test --test stdlib_reference_contract`: all five tests passed.
- `bash scripts/generate_unsafe_inventory.sh --strict`: passed.
- `git diff --check`: passed before both commits.
- `KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo bash scripts/validate.sh`: 218 assertions passed again.

The first full native run then found a second reference omission:
`docs/STANDARD_LIBRARY_REFERENCE.md` did not list the new builtin. Added its
preview row plus capability, trusted-root, failure and sync-guarantee semantics;
commit `719d6f7`. Both standard-library contract suites now pass (7 cases).

The corrected full `cargo test` completed successfully: 2,724 passed, zero failed,
15 existing ignored, across 83 suite summaries (including library tests compiled
for both library and CLI targets; this is not a unique-test count). The unchanged
freshness, standard-library and workflow-reference contracts all pass.
`bash scripts/repo_hygiene_audit.sh` and `cargo fmt --check` also passed.
Full test evidence: `evidence/durability/native-full-tests-20260925.txt`.

`cargo run -- test` also passed all 154 runnable fixtures (6 skipped), with no
interpreter fallback. Its five generated probe `.out` files were removed after
verification; the Kujo working tree is clean. Evidence:
`evidence/durability/native-language-tests-20260925.txt`.

Latest Linux rerun: 36131941147 at `719d6f7`. Formatting, clippy, MSRV,
VM/interpreter parity and minimal smoke all passed; the final broad release-gate
job 108062996557 also completed successfully. The entire Linux workflow is green.
ReaderSignal validation run 36133073639 at `9ae76c7` also completed successfully.
Terminal GitHub API receipts are preserved in `evidence/durability/` as
`linux-gate-completed.json` and `readersignal-ci-completed.json`.

## Restoration scope clarified

The user explicitly confirmed: “No live legacy restoration is needed.”
The repository task was to implement and verify recovery/backup mechanisms;
there is no existing damaged dataset to restore as part of this task. Requiring
operator paths was an unnecessary completion condition and is withdrawn.
The verified backup/restore commands remain available for future use. No live
data was changed or fabricated, and no backup paths are required to close this
work. Actual future restoration still requires trustworthy original evidence.

## Memory receipt

Merged the CI diagnosis and fixes into existing Strata Agent Notes handoff
`41a2b2ad-dff9-423a-9bab-af0a7d57c207`, revision 4. Exact retrieval and conceptual
search `ReaderSignal directory sync arity CI backup evidence` both returned the
updated handoff. No duplicate note or SignalBox capture was created: the two
confirmed defects are fixed, and pending verification is not a capture candidate.

The same Strata handoff was advanced to revision 5 with the second reference fix
and full Rust suite result; exact and conceptual retrieval passed. The terminal
language-runner receipt supersedes its previously pending local-run status.

## Completion

All identified implementation, documentation and regression fixes are committed
and pushed. Local full verification and both Linux workflows pass. The user
clarification removes the only outstanding operator-input condition; no known
required work remains. This supersedes the prior blocked handoff and pending-CI
receipts, which are retained as historical evidence.

The final documentation commit records this closure without changing executable
source. Kujo implementation/documentation ending SHA is
`719d6f7340bf179bcbd8b63b7eb551b51769d671`; ReaderSignal's tested SHA is
`9ae76c7e68404d1e4e093bb4526e516519868d56`. Use `git log -1 --format=%H --
docs/audits/durability-follow-up.md` to identify this closure commit.

Final Strata receipt: merged the explicit no-restoration requirement and both
successful CI results into existing Agent Notes handoff
`41a2b2ad-dff9-423a-9bab-af0a7d57c207`, revision 7. This explicitly supersedes
the prior blocked/pending status. Exact retrieval and conceptual search both
returned the updated note. No duplicate note was created. SignalBox: no captures
warranted.
