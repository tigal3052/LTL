# Backup Manifest

date: 2026-05-22
harness: agent-harness
reason: strict implementation gate hardening

## Files

- source: D:/Programming/ex_workspace/agent-harness/tools/comment-first-gate.ps1
  backup: docs/comment-gates/backups/2026-05-22/agent-harness-strict-implementation/comment-first-gate.ps1.bak
  restore: Copy-Item -LiteralPath docs/comment-gates/backups/2026-05-22/agent-harness-strict-implementation/comment-first-gate.ps1.bak -Destination D:/Programming/ex_workspace/agent-harness/tools/comment-first-gate.ps1 -Force
- source: D:/Programming/ex_workspace/agent-harness/docs/comment-first-enforcement.md
  backup: docs/comment-gates/backups/2026-05-22/agent-harness-strict-implementation/comment-first-enforcement.md.bak
  restore: Copy-Item -LiteralPath docs/comment-gates/backups/2026-05-22/agent-harness-strict-implementation/comment-first-enforcement.md.bak -Destination D:/Programming/ex_workspace/agent-harness/docs/comment-first-enforcement.md -Force
- source: D:/Programming/ex_workspace/agent-harness/docs/phase-gate-examples.md
  backup: docs/comment-gates/backups/2026-05-22/agent-harness-strict-implementation/phase-gate-examples.md.bak
  restore: Copy-Item -LiteralPath docs/comment-gates/backups/2026-05-22/agent-harness-strict-implementation/phase-gate-examples.md.bak -Destination D:/Programming/ex_workspace/agent-harness/docs/phase-gate-examples.md -Force
- source: D:/Programming/ex_workspace/agent-harness/docs/templates/comment-gate-ledger-template.md
  backup: docs/comment-gates/backups/2026-05-22/agent-harness-strict-implementation/comment-gate-ledger-template.md.bak
  restore: Copy-Item -LiteralPath docs/comment-gates/backups/2026-05-22/agent-harness-strict-implementation/comment-gate-ledger-template.md.bak -Destination D:/Programming/ex_workspace/agent-harness/docs/templates/comment-gate-ledger-template.md -Force
