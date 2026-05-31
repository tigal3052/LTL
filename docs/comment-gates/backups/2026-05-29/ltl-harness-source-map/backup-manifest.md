# Backup Manifest: ltl-harness-source-map

- Date: 2026-05-29
- Reason: Preserve harness entrypoint files before adding the source-map maintenance gate.

| Source | Backup | Restore command |
|---|---|---|
| `LTL-harness/README.md` | `docs/comment-gates/backups/2026-05-29/ltl-harness-source-map/README.md.bak` | `Copy-Item -LiteralPath 'docs/comment-gates/backups/2026-05-29/ltl-harness-source-map/README.md.bak' -Destination 'LTL-harness/README.md' -Force` |
| `LTL-harness/00_AGENTS.md` | `docs/comment-gates/backups/2026-05-29/ltl-harness-source-map/00_AGENTS.md.bak` | `Copy-Item -LiteralPath 'docs/comment-gates/backups/2026-05-29/ltl-harness-source-map/00_AGENTS.md.bak' -Destination 'LTL-harness/00_AGENTS.md' -Force` |
| `tools/run-compile-check.ps1` | `docs/comment-gates/backups/2026-05-29/ltl-harness-source-map/run-compile-check.ps1.bak` | `Copy-Item -LiteralPath 'docs/comment-gates/backups/2026-05-29/ltl-harness-source-map/run-compile-check.ps1.bak' -Destination 'tools/run-compile-check.ps1' -Force` |
