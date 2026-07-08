# Backup Manifest

date: 2026-05-22
harness: ltl-harness
reason: strict implementation gate hardening

## Files

- source: LTL-harness/tools/comment-first-gate.ps1
  backup: docs/comment-gates/backups/2026-05-22/ltl-harness-strict-implementation/comment-first-gate.ps1.bak
  restore: Copy-Item -LiteralPath docs/comment-gates/backups/2026-05-22/ltl-harness-strict-implementation/comment-first-gate.ps1.bak -Destination LTL-harness/tools/comment-first-gate.ps1 -Force
- source: LTL-harness/docs/comment-first-enforcement.md
  backup: docs/comment-gates/backups/2026-05-22/ltl-harness-strict-implementation/comment-first-enforcement.md.bak
  restore: Copy-Item -LiteralPath docs/comment-gates/backups/2026-05-22/ltl-harness-strict-implementation/comment-first-enforcement.md.bak -Destination LTL-harness/docs/comment-first-enforcement.md -Force
- source: LTL-harness/docs/phase-gate-examples.md
  backup: docs/comment-gates/backups/2026-05-22/ltl-harness-strict-implementation/phase-gate-examples.md.bak
  restore: Copy-Item -LiteralPath docs/comment-gates/backups/2026-05-22/ltl-harness-strict-implementation/phase-gate-examples.md.bak -Destination LTL-harness/docs/phase-gate-examples.md -Force
- source: LTL-harness/docs/templates/comment-gate-ledger-template.md
  backup: docs/comment-gates/backups/2026-05-22/ltl-harness-strict-implementation/comment-gate-ledger-template.md.bak
  restore: Copy-Item -LiteralPath docs/comment-gates/backups/2026-05-22/ltl-harness-strict-implementation/comment-gate-ledger-template.md.bak -Destination LTL-harness/docs/templates/comment-gate-ledger-template.md -Force
