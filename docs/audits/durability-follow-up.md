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
job is running (job 108062996557). Its success is not yet claimed.

## Historical evidence constraint

The repository contains backup schema and isolated recovery fixtures, but no
operator-supplied damaged-state directory or trusted original backup. Existing
checkpoint support cannot establish the provenance of an unspecified backup or
reconstruct missing historical bytes. Real-data restoration requires those two
paths (and original record plus creation event), or confirmation that no live
legacy state needs restoration. No live data has been changed or fabricated.

## Memory receipt

Merged the CI diagnosis and fixes into existing Strata Agent Notes handoff
`41a2b2ad-dff9-423a-9bab-af0a7d57c207`, revision 4. Exact retrieval and conceptual
search `ReaderSignal directory sync arity CI backup evidence` both returned the
updated handoff. No duplicate note or SignalBox capture was created: the two
confirmed defects are fixed, and pending verification is not a capture candidate.

The same Strata handoff was advanced to revision 5 with the second reference fix
and full Rust suite result; exact and conceptual retrieval passed. The terminal
language-runner receipt supersedes its previously pending local-run status.

## Required operator input

Across three goal turns, the damaged-state and trusted-backup paths remain
unspecified. No local live ReaderSignal state was identified in the repository.
All currently identified code/documentation fixes are committed and the full local
suites pass. Actual historical restoration cannot proceed until the operator
supplies those paths or confirms there is no live legacy dataset to restore.
The final Linux gate is independently running; resume by reading existing run
36131941147 rather than restarting it, and inspect any terminal failure before
claiming full CI completion. Goal completion is not claimed.

Strata handoff `41a2b2ad-dff9-423a-9bab-af0a7d57c207`, revision 6, now records
the passing language runner and exact resume job plus the missing operator input.
Exact retrieval and conceptual search both passed. No duplicate note or SignalBox
Capture/Signal was created. The local CI observer was stopped; the remote GitHub
job was not canceled.
