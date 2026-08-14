# Security and authority

ReaderSignal is local-first. State paths are explicit, record IDs reject traversal, record symlinks are refused, inputs are limited to 1 MiB, artifacts to 64 MiB, writes are atomic, and existing IDs are never overwritten. `--force` cannot bypass evidence, approval, authorization, or safety. Secrets must not enter records. Authority is OBSERVE/PROPOSE; only PressWire effect commands enter ACT with exact approval scope and `--act --yes`.
