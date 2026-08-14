# Quickstart

`./bin/readersignal init --state /tmp/readersignal-demo --json`

`./bin/readersignal snapshot --state /tmp/readersignal-demo --input fixtures/core.json --actor operator --timestamp 2026-08-14T00:00:00Z --json`

The fixed timestamp makes fixture IDs deterministic; repeating the command is rejected.
