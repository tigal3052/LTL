# Source Cleanup Deletion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove duplicate, obsolete, generated, and quarantined source residue from `LootingTheLeviathan` without deleting runtime or verification material still referenced by the Godot project.

**Architecture:** Treat `app-LTL/src/**`, `app-LTL/tests/**`, `app-LTL/src/data/**`, and referenced UI assets as the formal product surface. Treat `app-LTL/prototype/**`, `docs/comment-gates/backups/**`, and ignored local cache/worktree folders as cleanup candidates, but only delete after each path has a reference check and a passing verification command. Prototype replay fixtures are currently part of formal verification, so they must be promoted before broader prototype deletion.

**Tech Stack:** Godot 4.3 GDScript, PowerShell cleanup scripts, Git path/reference checks, existing Godot contract runner.

---

## Current Audit Snapshot

- `git status --short` is clean before this plan.
- Runtime main scene is `app-LTL/src/Main.tscn`, configured by `app-LTL/project.godot`.
- `app-LTL/README.md` states that `res://prototype/**` is archived reference material only and future work should extend `src/**`.
- `app-LTL/src/tools/FormalReplayRunner.gd` still reads replay fixtures from `res://prototype/browser-p0-p4/tests/fixtures/input_logs`.
- `app-LTL/tests/godot_contract_runner.gd` also directly loads those prototype fixture paths.
- `app-LTL/src/ui/BackpackUI.gd` loads `res://resources/UI/backpack_1.png` through `backpack_9.png`; those nine slice images are active runtime assets.
- `app-LTL/src/Main.tscn` loads `res://resources/UI/Log_Panel.png`; that image is an active runtime asset.
- `app-LTL/resources/UI/backpack.png` is only referenced by `app-LTL/tests/inspect_img.gd`, so it is not runtime-critical but may be the source atlas for the nine active slices.
- Ignored generated/local directories include `.cursor/`, `.godot-user/`, `.worktrees/`, `app-LTL/.godot/`, `app-LTL/_quarantine_comment_first_violation_2026-05-21/`, and ignored portions of `LTL-harness/`.
- Exact duplicate content currently detected outside ignored Godot caches:
  - `app-LTL/prototype/.gdignore` and `app-LTL/_quarantine_comment_first_violation_2026-05-21/.gdignore`
  - duplicated harness backup files under `docs/comment-gates/backups/2026-05-21`, `2026-05-22`, and `2026-05-26`
- Empty local directories currently present:
  - `script_templates/`
  - `app-LTL/export_templates/`
  - `app-LTL/feature_profiles/`
  - `app-LTL/script_templates/`
  - `app-LTL/text_editor_themes/`

## Deletion Approval Boundary

No deletion command should run until the user approves the exact candidate list for that task. All non-deletion work in this plan can proceed automatically, including audits, test updates, fixture promotion, plan updates, branch creation, and verification commands.

## Keep List

- Keep `app-LTL/src/**`.
- Keep `app-LTL/tests/**`, except `app-LTL/tests/inspect_img.gd` can be deleted only together with a decision to drop `app-LTL/resources/UI/backpack.png`.
- Keep `app-LTL/src/data/**`.
- Keep `app-LTL/src/scenes/**`.
- Keep `app-LTL/resources/UI/backpack_1.png` through `app-LTL/resources/UI/backpack_9.png` and their `.import` files because runtime code loads them.
- Keep `app-LTL/resources/UI/Log_Panel.png` and `Log_Panel.png.import` because `Main.tscn` loads it.
- Keep `app-LTL/prototype/browser-p0-p4/tests/fixtures/input_logs/*.json` until Task 4 promotes the fixtures and updates all references.
- Keep `LTL-harness/00_AGENTS.md`, `LTL-harness/docs/11_exec-plans/02_completed/09_M3_reward_and_progression_completed.md`, `LTL-harness/docs/i18n-text-enforcement.md`, and `LTL-harness/tools/i18n-text-gate.ps1` unless a separate harness ownership decision removes tracked harness material.

## Candidate Classes

### Class A: Local Generated Or Empty Residue

These are not source-of-truth files. Delete after a short explicit approval because they are local/cache/empty residue:

- `.godot-user/`
- `app-LTL/.godot/`
- `.cursor/`
- empty `script_templates/`
- empty `app-LTL/export_templates/`
- empty `app-LTL/feature_profiles/`
- empty `app-LTL/script_templates/`
- empty `app-LTL/text_editor_themes/`

`.worktrees/` is ignored but should not be deleted until `git worktree list` confirms it is stale or the user explicitly wants local worktrees removed.

### Class B: Quarantine And Backup Residue

These are likely deletion targets, but they preserve historical recovery material:

- `app-LTL/_quarantine_comment_first_violation_2026-05-21/`
- duplicated or stale files under `docs/comment-gates/backups/**`

Delete only after recording the backup manifests in the worklog or after the user confirms history in Git is enough.

### Class C: Archived Prototype Code

These are not formal runtime targets, but they are still useful reference material or verification input:

- `app-LTL/prototype/godot-p0/**`: likely obsolete and internally broken because files preload `res://prototype/domain/...` while the actual files live below `prototype/godot-p0/domain`.
- `app-LTL/prototype/browser-p0-p4/src/**`, `public/**`, `package.json`, and most JS tests: archived reference only.
- `app-LTL/prototype/browser-p0-p4/tests/fixtures/input_logs/*.json`: currently active verification fixtures and must not be deleted until promoted.

## Task 1: Reconfirm The Baseline

**Files:**
- Read: repository tree, Git status, relevant reference paths
- Modify: none
- Test: none

- [ ] **Step 1: Confirm clean status**

Run:

```powershell
git status --short
```

Expected: no output, or only the plan/worklog files created for this cleanup pass.

- [ ] **Step 2: Confirm ignored residue**

Run:

```powershell
git status --ignored --short
```

Expected: ignored entries include `.cursor/`, `.godot-user/`, `.worktrees/`, `app-LTL/.godot/`, and `app-LTL/_quarantine_comment_first_violation_2026-05-21/`.

- [ ] **Step 3: Re-run reference scan**

Run:

```powershell
rg -n "res://prototype|prototype/browser-p0-p4/tests/fixtures|res://resources/UI/backpack|res://resources/UI/Log_Panel" app-LTL docs tools LTL-harness
```

Expected:
- `app-LTL/src/tools/FormalReplayRunner.gd` and `app-LTL/tests/godot_contract_runner.gd` reference prototype fixture JSON files.
- `app-LTL/src/ui/BackpackUI.gd` references `backpack_%d.png`.
- `app-LTL/src/Main.tscn` references `Log_Panel.png`.

## Task 2: Delete Local Generated And Empty Residue

**Files:**
- Delete after approval: `.godot-user/`, `app-LTL/.godot/`, `.cursor/`, `script_templates/`, `app-LTL/export_templates/`, `app-LTL/feature_profiles/`, `app-LTL/script_templates/`, `app-LTL/text_editor_themes/`
- Modify: none
- Test: Godot contract runner after deletion

- [ ] **Step 1: Ask for deletion approval**

Ask the user to approve exactly this deletion set:

```text
.godot-user/
app-LTL/.godot/
.cursor/
script_templates/
app-LTL/export_templates/
app-LTL/feature_profiles/
app-LTL/script_templates/
app-LTL/text_editor_themes/
```

Expected: user approval before deletion.

- [ ] **Step 2: Delete approved local residue**

Run only after approval:

```powershell
Remove-Item -LiteralPath '.godot-user' -Recurse -Force
Remove-Item -LiteralPath 'app-LTL\.godot' -Recurse -Force
Remove-Item -LiteralPath '.cursor' -Recurse -Force
Remove-Item -LiteralPath 'script_templates' -Recurse -Force
Remove-Item -LiteralPath 'app-LTL\export_templates' -Recurse -Force
Remove-Item -LiteralPath 'app-LTL\feature_profiles' -Recurse -Force
Remove-Item -LiteralPath 'app-LTL\script_templates' -Recurse -Force
Remove-Item -LiteralPath 'app-LTL\text_editor_themes' -Recurse -Force
```

Expected: paths are removed locally. If Godot recreates `app-LTL/.godot/`, it remains ignored.

- [ ] **Step 3: Verify no source files changed**

Run:

```powershell
git status --short
```

Expected: no tracked source changes from this task.

## Task 3: Delete Quarantine Folder

**Files:**
- Delete after approval: `app-LTL/_quarantine_comment_first_violation_2026-05-21/**`
- Modify: none
- Test: Godot contract runner

- [ ] **Step 1: Reconfirm quarantine is unreferenced by runtime**

Run:

```powershell
rg -n "_quarantine_comment_first_violation_2026-05-21|_quarantine" app-LTL docs tools LTL-harness
```

Expected: only policy/tooling references, not runtime `load`, `preload`, or scene references.

- [ ] **Step 2: Ask for deletion approval**

Ask the user to approve deleting:

```text
app-LTL/_quarantine_comment_first_violation_2026-05-21/
```

Expected: user approval before deletion.

- [ ] **Step 3: Delete approved quarantine folder**

Run only after approval:

```powershell
Remove-Item -LiteralPath 'app-LTL\_quarantine_comment_first_violation_2026-05-21' -Recurse -Force
```

Expected: quarantine folder is gone.

- [ ] **Step 4: Verify**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
git diff --check
```

Expected: compile check passes with `GODOT_CONTRACTS_OK`; `git diff --check` reports no whitespace errors.

## Task 4: Promote Prototype Replay Fixtures

**Files:**
- Create: `app-LTL/tests/fixtures/input_logs/basic_clear.json`
- Create: `app-LTL/tests/fixtures/input_logs/empty_queue_repair.json`
- Modify: `app-LTL/src/tools/FormalReplayRunner.gd`
- Modify: `app-LTL/tests/godot_contract_runner.gd`
- Delete after later approval: original prototype fixture copies

- [ ] **Step 1: Copy fixtures into formal test location**

Run:

```powershell
New-Item -ItemType Directory -Force -Path 'app-LTL\tests\fixtures\input_logs'
Copy-Item -LiteralPath 'app-LTL\prototype\browser-p0-p4\tests\fixtures\input_logs\basic_clear.json' -Destination 'app-LTL\tests\fixtures\input_logs\basic_clear.json'
Copy-Item -LiteralPath 'app-LTL\prototype\browser-p0-p4\tests\fixtures\input_logs\empty_queue_repair.json' -Destination 'app-LTL\tests\fixtures\input_logs\empty_queue_repair.json'
```

Expected: fixture JSON files exist under `app-LTL/tests/fixtures/input_logs/`.

- [ ] **Step 2: Update `FormalReplayRunner.gd` fixture base path**

Change:

```gdscript
var base := "res://prototype/browser-p0-p4/tests/fixtures/input_logs"
```

To:

```gdscript
var base := "res://tests/fixtures/input_logs"
```

- [ ] **Step 3: Update `godot_contract_runner.gd` explicit fixture paths**

Change:

```gdscript
var replay_report: Dictionary = replay_runner.run_all({"fixturePaths": ["res://prototype/browser-p0-p4/tests/fixtures/input_logs/basic_clear.json", "res://prototype/browser-p0-p4/tests/fixtures/input_logs/empty_queue_repair.json"]})
```

To:

```gdscript
var replay_report: Dictionary = replay_runner.run_all({"fixturePaths": ["res://tests/fixtures/input_logs/basic_clear.json", "res://tests/fixtures/input_logs/empty_queue_repair.json"]})
```

- [ ] **Step 4: Verify promoted fixture path**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
rg -n "prototype/browser-p0-p4/tests/fixtures" app-LTL/src app-LTL/tests
```

Expected: compile check passes with `GODOT_CONTRACTS_OK`; the `rg` command returns no matches in formal source/tests.

## Task 5: Delete Obsolete Godot Prototype

**Files:**
- Delete after approval: `app-LTL/prototype/godot-p0/**`
- Modify: none
- Test: Godot contract runner

- [ ] **Step 1: Reconfirm no formal references**

Run:

```powershell
rg -n "prototype/godot-p0|res://prototype/godot-p0|PrototypeController|PrototypeMain" app-LTL/src app-LTL/tests docs tools LTL-harness
```

Expected: no formal runtime or test references.

- [ ] **Step 2: Ask for deletion approval**

Ask the user to approve deleting:

```text
app-LTL/prototype/godot-p0/
```

Expected: user approval before deletion.

- [ ] **Step 3: Delete approved obsolete Godot prototype**

Run only after approval:

```powershell
Remove-Item -LiteralPath 'app-LTL\prototype\godot-p0' -Recurse -Force
```

Expected: `godot-p0` prototype folder is removed.

- [ ] **Step 4: Verify**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
git diff --check
```

Expected: compile check passes with `GODOT_CONTRACTS_OK`; no whitespace errors.

## Task 6: Decide Browser Prototype Retention Or Deletion

**Files:**
- Candidate delete after approval: `app-LTL/prototype/browser-p0-p4/src/**`, `public/**`, `package.json`, most `tests/*.js`
- Candidate keep: `app-LTL/prototype/.gdignore`, or delete entire `prototype/` after all prototype children are removed
- Test: Godot contract runner

- [ ] **Step 1: Confirm fixtures were promoted**

Run:

```powershell
rg -n "prototype/browser-p0-p4/tests/fixtures|res://prototype/browser-p0-p4" app-LTL/src app-LTL/tests
```

Expected: no matches in formal source/tests.

- [ ] **Step 2: Ask for browser prototype policy**

Offer the user two deletion choices:

```text
Option 1: Keep browser prototype as archived reference code.
Option 2: Delete browser prototype runtime/test source after fixture promotion.
```

Expected: explicit user choice before deletion.

- [ ] **Step 3: Delete browser prototype source if approved**

Run only if the user chooses deletion:

```powershell
Remove-Item -LiteralPath 'app-LTL\prototype\browser-p0-p4\src' -Recurse -Force
Remove-Item -LiteralPath 'app-LTL\prototype\browser-p0-p4\public' -Recurse -Force
Remove-Item -LiteralPath 'app-LTL\prototype\browser-p0-p4\tests' -Recurse -Force
Remove-Item -LiteralPath 'app-LTL\prototype\browser-p0-p4\package.json' -Force
```

Expected: browser prototype runtime/test source is removed. If `app-LTL/prototype/browser-p0-p4/` becomes empty, ask for approval before removing the empty directory too.

- [ ] **Step 4: Verify**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
git diff --check
```

Expected: compile check passes with `GODOT_CONTRACTS_OK`; no whitespace errors.

## Task 7: Clean Backup Duplicates

**Files:**
- Candidate delete after approval: duplicated/stale files under `docs/comment-gates/backups/**`
- Modify if needed: `tools/apply-agent-harness-phase-gate.ps1`
- Test: reference scan and compile check

- [ ] **Step 1: Generate duplicate backup report**

Run:

```powershell
$files = Get-ChildItem -LiteralPath 'docs\comment-gates\backups' -Recurse -File
$items = foreach ($file in $files) {
  $hash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
  [PSCustomObject]@{ Hash=$hash.Hash; Length=$file.Length; Path=$file.FullName.Replace((Get-Location).Path + '\','') }
}
$items | Group-Object Hash | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Group | Select-Object Length,Path }
```

Expected: duplicate pairs include the `comment-first-enforcement.md.bak` pair and 2026-05-26 architectural backup pairs.

- [ ] **Step 2: Ask for deletion approval**

Ask the user to approve exact duplicate backup deletion paths from Step 1.

Expected: user approval before deletion.

- [ ] **Step 3: Delete approved duplicate backup files**

Run one `Remove-Item -LiteralPath '<approved path>' -Force` per approved file.

Expected: only approved duplicate backup copies are removed.

- [ ] **Step 4: Verify**

Run:

```powershell
rg -n "docs/comment-gates/backups" tools docs
git status --short
git diff --check
```

Expected: tooling references still describe backup policy; Git shows only approved backup deletions and plan/worklog changes; no whitespace errors.

## Task 8: Decide Source Atlas Retention

**Files:**
- Candidate delete after approval: `app-LTL/resources/UI/backpack.png`, `app-LTL/resources/UI/backpack.png.import`, `app-LTL/tests/inspect_img.gd`
- Keep: `app-LTL/resources/UI/backpack_1.png` through `backpack_9.png`
- Test: Godot contract runner

- [ ] **Step 1: Reconfirm active asset references**

Run:

```powershell
rg -n "backpack\\.png|backpack_%d|backpack_[1-9]\\.png" app-LTL/src app-LTL/tests app-LTL/*.godot app-LTL/resources
```

Expected:
- Runtime code references `backpack_%d.png`.
- `inspect_img.gd` references `backpack.png`.
- No runtime scene/script depends directly on `backpack.png`.

- [ ] **Step 2: Ask for atlas policy**

Offer the user two deletion choices:

```text
Option 1: Keep backpack.png as source atlas for future reslicing.
Option 2: Delete backpack.png and its diagnostic inspect_img.gd because runtime uses only sliced assets.
```

Expected: explicit user choice before deletion.

- [ ] **Step 3: Delete atlas and diagnostic script if approved**

Run only if the user chooses deletion:

```powershell
Remove-Item -LiteralPath 'app-LTL\resources\UI\backpack.png' -Force
Remove-Item -LiteralPath 'app-LTL\resources\UI\backpack.png.import' -Force
Remove-Item -LiteralPath 'app-LTL\tests\inspect_img.gd' -Force
```

Expected: source atlas and diagnostic script are removed; sliced runtime assets remain.

- [ ] **Step 4: Verify**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
git diff --check
```

Expected: compile check passes with `GODOT_CONTRACTS_OK`; no whitespace errors.

## Task 9: Final Verification And Report

**Files:**
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-05-29.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-05-29.md`

- [ ] **Step 1: Run final source reference scan**

Run:

```powershell
rg -n "res://prototype|_quarantine_comment_first_violation|prototype/browser-p0-p4/tests/fixtures" app-LTL/src app-LTL/tests app-LTL/project.godot
```

Expected: no matches unless the user chose to retain browser prototype fixtures or prototype reference material intentionally.

- [ ] **Step 2: Run formal verification**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
git diff --check
git status --short
```

Expected:
- compile check passes with `GODOT_CONTRACTS_OK`
- no whitespace errors
- status contains only approved deletions, fixture promotion edits, and worklog/plan updates

- [ ] **Step 3: Update worklog completion**

Record:
- approved deletion set
- deferred deletion set
- verification commands and results
- any retained paths with rationale

- [ ] **Step 4: Final response**

Report:
- what was deleted
- what was intentionally kept
- what remains deferred for a later approval
- exact verification results

## Self-Review

- Spec coverage: The plan covers the user's request to review the full source tree, identify duplicate or unnecessary residue, and preserve deletion as the only explicit approval point.
- Placeholder scan: The plan has no unfinished placeholder markers or unspecified delete command. Every deletion task lists exact paths and approval gates.
- Type/path consistency: Formal fixture paths consistently move from `res://prototype/browser-p0-p4/tests/fixtures/input_logs` to `res://tests/fixtures/input_logs`.
