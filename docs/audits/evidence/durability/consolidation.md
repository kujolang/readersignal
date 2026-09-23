# Durable memory receipt — 2026-09-23

Storage: Strata **Agent Notes**. Scope: ReaderSignal and its explicitly authorized
Kujo directory-durability dependency.

- Saved one cross-repository handoff, `41a2b2ad-dff9-423a-9bab-af0a7d57c207`
  (revision 3): ordered durable publication, bounded trusted backup/restore,
  Linux O_PATH correction, verified commits and evidence pointers, remaining
  need for real original backup evidence and supplied state paths.
- Annotated the earlier handoff `3312325a-294f-4f8c-8676-e7bb8c5eadda`
  (revision 2) with a supersession link. Preserved its historical findings and
  still-applicable trusted-root and missing-original-evidence constraints.
- Deduplicated against the existing project memories before writing; did not
  create duplicate atomic notes for the same episode.
- Final exact retrieval returned the new handoff at revision 3. Conceptual query
  `ReaderSignal trusted backup restore power-loss ordering` (limit 3) returned
  that same handoff. Both supported CLI operations succeeded.
- No additional project hub or timeline was duplicated; the handoff records the
  milestone and current state with repository provenance.

SignalBox: no captures warranted. The existing upstream durability item is
addressed by the implementation. Completed-work summaries, routine verification,
and pending CI were rejected as capture candidates. No new Capture or Signal,
no disposition, and no duplicate of the old durability finding were written.

Actual historical restoration remains conditional on trusted evidence supplied
by the operator. No undisclosed live dataset was restored.
