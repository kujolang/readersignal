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

Full native `cargo test` and the new Linux CI run 36131352261 were started to
verify beyond the previously failing contracts. Their terminal receipts will
be appended after completion; this report does not claim either has passed yet.

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
