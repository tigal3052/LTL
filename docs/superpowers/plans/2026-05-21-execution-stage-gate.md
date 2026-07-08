# Execution Stage Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make both the LTL harness and the generic `agent-harness` enforce three distinct authoring phases so formal files cannot advance from `계약 주석` to `실행 주석` to `구현` without the correct gate, ledger state, and local backup trail.

**Architecture:** Replace the current two-mode comment gate with a three-phase model: `contract-only`, `execution-only`, and `implementation`. Each harness gets the same enforcement document shape, the same phase-aware PowerShell gate, and the same ledger template. Because `LTL-harness` is ignored by the remote GitHub path rules and `agent-harness` may also need non-remote-safe recovery, the implementation flow uses explicit filesystem backups instead of commit-based checkpoints.

**Tech Stack:** PowerShell gate scripts, Markdown harness docs, Markdown ledgers under `docs/comment-gates/`, local filesystem backups under a dedicated backup directory

---

## File Structure

### LTL harness

- Modify: `LTL-harness/docs/comment-first-enforcement.md`
  - Document the new three-phase lifecycle, per-phase allowed content, hard-stop conditions, local backup rules, and recovery flow.
- Modify: `LTL-harness/tools/comment-first-gate.ps1`
  - Replace the current two-mode validator with a three-mode validator that understands phase-specific allowed markers and ledger requirements.
- Create: `LTL-harness/docs/templates/comment-gate-ledger-template.md`
  - Standardize ledger fields so the gate can parse phase, approval, targets, and advancement intent deterministically.
- Create: `LTL-harness/docs/templates/backup-manifest-template.md`
  - Standardize per-pass backup metadata for changed files and restore instructions.
- Modify: `LTL-harness/00_AGENTS.md`
  - Point agents to the new phase model and make phase advancement plus backup creation explicit.
- Create: `LTL-harness/docs/phase-gate-examples.md`
  - Show valid and invalid examples for each phase so misuse is easier to catch before editing starts.

### Generic agent harness

- Modify: `D:/Programming/ex_workspace/agent-harness/docs/comment-first-enforcement.md`
  - Mirror the same three-phase lifecycle and backup policy.
- Modify: `D:/Programming/ex_workspace/agent-harness/tools/comment-first-gate.ps1`
  - Mirror the same three-mode validator behavior.
- Create: `D:/Programming/ex_workspace/agent-harness/docs/templates/comment-gate-ledger-template.md`
  - Mirror the same machine-readable ledger format.
- Create: `D:/Programming/ex_workspace/agent-harness/docs/templates/backup-manifest-template.md`
  - Mirror the same backup manifest format.
- Modify: `D:/Programming/ex_workspace/agent-harness/00_AGENTS.md`
  - Mirror the same phase and backup requirements.
- Create: `D:/Programming/ex_workspace/agent-harness/docs/phase-gate-examples.md`
  - Mirror the same valid/invalid examples.

### Working ledgers and backup area

- Modify: `docs/comment-gates/2026-05-21-m0-m1-contract-comments.md`
  - Upgrade the current ledger to the new template after the gate system exists.
- Create: `docs/comment-gates/backups/`
  - Store timestamped manifests and file copies for the local backup/restore workflow.

### Test surface

- Test via: `LTL-harness/tools/comment-first-gate.ps1`
- Test via: `D:/Programming/ex_workspace/agent-harness/tools/comment-first-gate.ps1`

## Backup Policy

- Do not use Git commits as required checkpoints in this plan.
- Before editing any harness enforcement file, create a timestamped local backup copy under:
  - `docs/comment-gates/backups/<yyyy-mm-dd>/<harness-name>/`
- Each backup set must include a manifest file with:
  - source file path
  - backup file path
  - timestamp
  - reason for change
  - restore command
- Recovery must be possible with plain filesystem copy commands even if Git metadata is unavailable or the path is ignored by remote sync.

### Task 1: Rewrite the enforcement spec around three explicit phases in both harnesses

**Files:**
- Modify: `LTL-harness/docs/comment-first-enforcement.md`
- Modify: `LTL-harness/00_AGENTS.md`
- Create: `LTL-harness/docs/phase-gate-examples.md`
- Modify: `D:/Programming/ex_workspace/agent-harness/docs/comment-first-enforcement.md`
- Modify: `D:/Programming/ex_workspace/agent-harness/00_AGENTS.md`
- Create: `D:/Programming/ex_workspace/agent-harness/docs/phase-gate-examples.md`

- [ ] **Step 1: Create the example doc content for both harnesses**

```md
# Phase Gate Examples

## Valid: contract-only
- File contains `# 계약:` comments only.
- File contains no `# 실행:` lines.
- File contains no code tokens.

## Invalid: contract-only
- File contains any `# 실행:` line.
- File contains any GDScript or language-level implementation token.

## Valid: execution-only
- File contains `# 계약:` and `# 실행:` comments.
- File contains no code tokens.

## Invalid: execution-only
- File contains implementation code.
- File contains `# 실행:` lines that are not covered by the ledger phase.

## Valid: implementation
- File contains `# 계약:` comments.
- File contains `# 실행:` comments immediately above each code block.
- Ledger phase is `implementation-approved`.
```

- [ ] **Step 2: Update both enforcement docs to define the new lifecycle**

```md
## Required Phases

1. `contract-only`
   - Allowed: `계약:` comments only
   - Forbidden: `실행:` comments, implementation code
2. `execution-only`
   - Allowed: `계약:` comments, `실행:` comments
   - Forbidden: implementation code
3. `implementation`
   - Allowed: `계약:` comments, `실행:` comments, implementation code
   - Required: each code block must be directly guarded by one `실행:` comment

## Phase Advancement

- `contract-only -> execution-only` requires:
  - ledger exists
  - ledger phase is `execution-comment-requested`
  - explicit user approval recorded
- `execution-only -> implementation` requires:
  - ledger phase is `implementation-approved`
  - target file list matches
  - gate passes in `execution-only` mode before any code is added
```

- [ ] **Step 3: Update both `00_AGENTS.md` files to point at the new phase sequence**

```md
### Comment-first stage order
- Formal source work must advance through:
  1. contract-only
  2. execution-only
  3. implementation
- Skipping or collapsing phases is a harness violation.
- Before editing harness enforcement files, create a local backup manifest and file copy.
```

- [ ] **Step 4: Review docs for contradictions in both harnesses**

Run: `rg -n "comment-only|implementation|계약 주석|실행 주석" LTL-harness D:/Programming/ex_workspace/agent-harness`
Expected: references align with the new three-phase wording and no doc still implies `계약+실행` can be authored in one default step

- [ ] **Step 5: Save local backups of edited docs**

Run: `Copy-Item <source> docs/comment-gates/backups/<date>/<harness>/...`
Expected: each modified doc has a matching backup copy and manifest entry

### Task 2: Replace the two-mode PowerShell gate with a three-mode validator in both harnesses

**Files:**
- Modify: `LTL-harness/tools/comment-first-gate.ps1`
- Modify: `D:/Programming/ex_workspace/agent-harness/tools/comment-first-gate.ps1`

- [ ] **Step 1: Write the failing phase matrix into comments at the top of both scripts**

```powershell
# Modes to support:
# - contract-only
# - execution-only
# - implementation
#
# contract-only must fail if any execution marker exists
# execution-only must fail if any code token exists
# implementation must fail if code is not directly guarded by an execution marker
```

- [ ] **Step 2: Expand the mode parameter in both scripts**

```powershell
param(
  [Parameter(Mandatory=$true)]
  [ValidateSet("contract-only", "execution-only", "implementation")]
  [string]$Mode,
  [Parameter(Mandatory=$true)]
  [string]$Root,
  [Parameter(Mandatory=$true)]
  [string[]]$Targets,
  [string]$Ledger
)
```

- [ ] **Step 3: Add helpers for phase-specific markers in both scripts**

```powershell
function Has-ContractMarker($Text) {
  return $Text.Contains("계약:")
}

function Has-ExecutionMarker($Text) {
  return $Text.Contains("실행:")
}

function Assert-ContractOnly($Path) {
  $text = Get-Content -LiteralPath $Path -Raw
  if (-not (Has-ContractMarker $text)) { Fail "missing contract marker: $Path" }
  if (Has-ExecutionMarker $text) { Fail "contract-only gate failed: execution marker found in $Path" }
  Test-NoCodeTokens $Path
}

function Assert-ExecutionOnly($Path) {
  $text = Get-Content -LiteralPath $Path -Raw
  if (-not (Has-ContractMarker $text)) { Fail "missing contract marker: $Path" }
  if (-not (Has-ExecutionMarker $text)) { Fail "missing execution marker: $Path" }
  Test-NoCodeTokens $Path
}
```

- [ ] **Step 4: Separate ledger validation by phase in both scripts**

```powershell
function Assert-LedgerPhase($LedgerText, $ExpectedPhase) {
  if (-not $LedgerText.Contains("phase: $ExpectedPhase")) {
    Fail "ledger phase mismatch: expected $ExpectedPhase"
  }
}

if ($Mode -eq "execution-only") {
  Assert-LedgerPhase $ledgerText "execution-comment-requested"
}

if ($Mode -eq "implementation") {
  Assert-LedgerPhase $ledgerText "implementation-approved"
}
```

- [ ] **Step 5: Preserve the current implementation adjacency check in both scripts**

```powershell
if ($Mode -eq "implementation") {
  Test-Implementation $path
}
```

- [ ] **Step 6: Save local backups of the original scripts before replacement**

Run: `Copy-Item <script> docs/comment-gates/backups/<date>/<harness>/...`
Expected: both original scripts can be restored from filesystem copies

- [ ] **Step 7: Run manual positive and negative checks against both scripts**

Run: `powershell -ExecutionPolicy Bypass -File .\LTL-harness\tools\comment-first-gate.ps1 -Mode contract-only -Root . -Targets 'app-LTL/src/domain/FormalContracts.gd' -Ledger 'docs/comment-gates/2026-05-21-m0-m1-contract-comments.md'`
Expected: fails until ledger/template and file contents match the new phase rules

Run: `powershell -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/agent-harness/tools/comment-first-gate.ps1' -Mode contract-only -Root 'D:/Programming/ex_workspace/agent-harness' -Targets 'examples/phase-gate-fixtures/contract-only.txt' -Ledger 'D:/Programming/ex_workspace/agent-harness/docs/comment-gates/example-phase-ledger.md'`
Expected: fails until the generic harness fixture and ledger match the new phase rules

### Task 3: Standardize the ledger and backup manifest so phase advancement is machine-checkable

**Files:**
- Create: `LTL-harness/docs/templates/comment-gate-ledger-template.md`
- Create: `LTL-harness/docs/templates/backup-manifest-template.md`
- Modify: `docs/comment-gates/2026-05-21-m0-m1-contract-comments.md`
- Create: `D:/Programming/ex_workspace/agent-harness/docs/templates/comment-gate-ledger-template.md`
- Create: `D:/Programming/ex_workspace/agent-harness/docs/templates/backup-manifest-template.md`
- Create: `D:/Programming/ex_workspace/agent-harness/examples/phase-gate-fixtures/contract-only.txt`
- Create: `D:/Programming/ex_workspace/agent-harness/examples/phase-gate-fixtures/execution-only.txt`
- Create: `D:/Programming/ex_workspace/agent-harness/examples/phase-gate-fixtures/implementation.txt`
- Create: `D:/Programming/ex_workspace/agent-harness/docs/comment-gates/example-phase-ledger.md`

- [ ] **Step 1: Create the new ledger template in both harnesses**

```md
# Comment Gate Ledger

date: YYYY-MM-DD
task: short-task-name
phase: contract-only
approval: approved
targets:
  - path/to/target.file

## Contract Summary

## Execution Scope

## Advancement Rule
- next_phase: execution-only
- required_user_request: explicit
```

- [ ] **Step 2: Create the backup manifest template in both harnesses**

```md
# Backup Manifest

date: YYYY-MM-DD
harness: ltl-harness
reason: short-reason

## Files
- source: path/to/source
  backup: path/to/backup
  restore: Copy-Item -LiteralPath <backup> -Destination <source> -Force
```

- [ ] **Step 3: Migrate the current LTL ledger to the template**

```md
date: 2026-05-21
task: m0-m1-contract-comments
phase: execution-only
approval: approved
targets:
  - app-LTL/src/domain/FormalContracts.gd
```

- [ ] **Step 4: Add a gate-readable advancement section**

```md
## Advancement Rule
- current_phase_owner: contract-comments-complete
- next_phase: implementation
- required_user_request: explicit implementation request
```

- [ ] **Step 5: Verify the gate can parse template fields in both harnesses**

Run: `rg -n "^phase:|^approval:|^targets:" LTL-harness/docs/templates/comment-gate-ledger-template.md D:/Programming/ex_workspace/agent-harness/docs/templates/comment-gate-ledger-template.md docs/comment-gates/2026-05-21-m0-m1-contract-comments.md`
Expected: required machine-readable keys are consistent across both harnesses and the live LTL ledger

- [ ] **Step 6: Create generic phase-gate fixtures for the agent harness**

```text
D:/Programming/ex_workspace/agent-harness/examples/phase-gate-fixtures/contract-only.txt
D:/Programming/ex_workspace/agent-harness/examples/phase-gate-fixtures/execution-only.txt
D:/Programming/ex_workspace/agent-harness/examples/phase-gate-fixtures/implementation.txt
```

Use these contents:

```text
# contract-only.txt
# 계약:
# - purpose: generic contract-only fixture for comment gate verification
# - allowed: contract comments only
```

```text
# execution-only.txt
# 계약:
# - purpose: generic execution-only fixture for comment gate verification
# 실행:
# - purpose: generic execution comment fixture for phase advancement checks
```

```text
# implementation.txt
# 계약:
# - purpose: generic implementation fixture for comment gate verification
# 실행:
print("generic fixture")
```

- [ ] **Step 7: Create a generic agent-harness example ledger**

```md
# Comment Gate Ledger

date: YYYY-MM-DD
task: generic-phase-gate-example
phase: contract-only
approval: approved
targets:
  - examples/phase-gate-fixtures/contract-only.txt

## Contract Summary
- generic fixture for validating the contract-only phase

## Execution Scope
- target can later advance to execution-only and implementation using sibling fixture files

## Advancement Rule
- next_phase: execution-only
- required_user_request: explicit
```

- [ ] **Step 8: Verify the generic fixture and ledger names are purpose-oriented**

Run: `rg -n "example.gd|example-ledger.md" docs/superpowers/plans/2026-05-21-execution-stage-gate.md`
Expected: no remaining references to the old Godot-specific example names

### Task 4: Prove the new gate catches the exact mistake that happened and can be restored locally if it breaks

**Files:**
- Modify: `LTL-harness/docs/phase-gate-examples.md`
- Modify: `LTL-harness/tools/comment-first-gate.ps1`
- Modify: `D:/Programming/ex_workspace/agent-harness/docs/phase-gate-examples.md`
- Modify: `D:/Programming/ex_workspace/agent-harness/tools/comment-first-gate.ps1`

- [ ] **Step 1: Add a regression example for the observed failure in both example docs**

```md
## Regression: contract request accidentally includes execution comments
- Request: "계약 주석 작성"
- File state: contains `계약:` and `실행:`
- Expected: `contract-only` gate fails before implementation starts
```

- [ ] **Step 2: Add a regression branch in both script error messages**

```powershell
if ($Mode -eq "contract-only" -and (Has-ExecutionMarker $text)) {
  Fail "contract-only gate failed: execution comments were added before an execution-comment request in $Path"
}
```

- [ ] **Step 3: Run the regression check against the live LTL scaffold**

Run: `powershell -ExecutionPolicy Bypass -File .\LTL-harness\tools\comment-first-gate.ps1 -Mode contract-only -Root . -Targets 'app-LTL/src/domain/FormalContracts.gd' -Ledger 'docs/comment-gates/2026-05-21-m0-m1-contract-comments.md'`
Expected: FAIL with an error stating execution comments were added before the execution-comment phase

- [ ] **Step 4: Run a success case for `execution-only` on the same LTL file**

Run: `powershell -ExecutionPolicy Bypass -File .\LTL-harness\tools\comment-first-gate.ps1 -Mode execution-only -Root . -Targets 'app-LTL/src/domain/FormalContracts.gd' -Ledger 'docs/comment-gates/2026-05-21-m0-m1-contract-comments.md'`
Expected: PASS once ledger phase and file contents match the new execution-only rules

- [ ] **Step 5: Run the same regression/success pair against an `agent-harness` fixture**

Run: `powershell -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/agent-harness/tools/comment-first-gate.ps1' -Mode contract-only -Root 'D:/Programming/ex_workspace/agent-harness' -Targets 'examples/phase-gate-fixtures/execution-only.txt' -Ledger 'D:/Programming/ex_workspace/agent-harness/docs/comment-gates/example-phase-ledger.md'`
Expected: FAIL for premature execution comments

Run: `powershell -ExecutionPolicy Bypass -File 'D:/Programming/ex_workspace/agent-harness/tools/comment-first-gate.ps1' -Mode execution-only -Root 'D:/Programming/ex_workspace/agent-harness' -Targets 'examples/phase-gate-fixtures/execution-only.txt' -Ledger 'D:/Programming/ex_workspace/agent-harness/docs/comment-gates/example-phase-ledger.md'`
Expected: PASS once the generic fixture and ledger satisfy the new execution-only rules

- [ ] **Step 6: Prove restore from local backups**

Run: `Copy-Item -LiteralPath <backup-path> -Destination <source-path> -Force`
Expected: any modified enforcement doc or script can be restored without Git history

## Self-Review

- Spec coverage:
  - phase separation problem: covered by Tasks 1-4
  - local backup/restore instead of Git commits: covered by Backup Policy and Tasks 1-4
  - application to both `LTL-harness` and `agent-harness`: covered by every task
- Placeholder scan:
  - no `TODO`, `TBD`, or vague "handle appropriately" language left in steps
- Type consistency:
  - plan consistently uses `contract-only`, `execution-only`, and `implementation`
  - plan consistently uses local backup manifests instead of commit checkpoints

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-21-execution-stage-gate.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
