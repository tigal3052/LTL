# Transition Safety Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a blocking transition-safety harness gate so transition-affecting work must declare and prove handoff stability, including the reward ceremony to reward board boundary.

**Architecture:** Keep transition safety separate from the existing architectural gate. Extend request-analysis artifacts so ledgers must record transition review, add a dedicated PowerShell gate with a small built-in registry plus self-tests, then add a focused Godot reward-handoff proof and wire the new gate into compile and quality verification paths.

**Tech Stack:** PowerShell harness scripts, Markdown SoT docs, Godot 4.3 headless contract runners, GDScript scene-tree flow tests.

---

### Task 1: Document and Ledger Surface

**Files:**
- Create: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\docs\transition-safety-gate.md`
- Create: `D:\Programming\ex_workspace\LootingTheLeviathan\docs\request-ledgers\2026-06-09-transition-safety-gate.md`
- Create: `D:\Programming\ex_workspace\LootingTheLeviathan\docs\artifact-ledgers\2026-06-09-transition-safety-gate.md`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\docs\request-analysis-execution-gate.md`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\docs\templates\request-constraint-ledger-template.md`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\tools\request-analysis-gate.ps1`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\tools\request-analysis-gate.tests.ps1`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\docs\request-ledgers\2026-06-02-refactor-harness-quality-gate.md`

- [ ] **Step 1: Create backup copies for touched harness enforcement files**

```powershell
New-Item -ItemType Directory -Force -Path "docs/comment-gates/backups/2026-06-09/ltl-harness/tools" | Out-Null
New-Item -ItemType Directory -Force -Path "docs/comment-gates/backups/2026-06-09/ltl-harness/docs/templates" | Out-Null
Copy-Item "LTL-harness/tools/request-analysis-gate.ps1" "docs/comment-gates/backups/2026-06-09/ltl-harness/tools/request-analysis-gate.ps1"
Copy-Item "LTL-harness/tools/request-analysis-gate.tests.ps1" "docs/comment-gates/backups/2026-06-09/ltl-harness/tools/request-analysis-gate.tests.ps1"
Copy-Item "LTL-harness/docs/request-analysis-execution-gate.md" "docs/comment-gates/backups/2026-06-09/ltl-harness/docs/request-analysis-execution-gate.md"
Copy-Item "LTL-harness/docs/templates/request-constraint-ledger-template.md" "docs/comment-gates/backups/2026-06-09/ltl-harness/docs/templates/request-constraint-ledger-template.md"
```

- [ ] **Step 2: Write the transition-safety request ledger and artifact ledger**

```markdown
## Transition Safety Review

- touched transition ids: `meta.start_flow`, `page.scene_mapping`, `reward.ceremony`, `reward.handoff`
- entry owner: `app-LTL/src/MainControllerRuntime.gd`
- exit owner: `app-LTL/src/ui/MainViewRuntime.gd`
- shared handoff risks: reward presentation step change, shared backpack reparent, reward-board layout sync, marker-only false green risk
- required runners:
  - `app-LTL/tests/run_main_start_flow_contract.gd` -> `MAIN_START_FLOW_CONTRACT_OK`
  - `app-LTL/tests/run_page_scene_mapping_contract.gd` -> `PAGE_SCENE_MAPPING_CONTRACT_OK`
  - `app-LTL/tests/run_reward_ceremony_contract.gd` -> `REWARD_CEREMONY_CONTRACT_OK`
  - `app-LTL/tests/run_reward_handoff_contract.gd` -> `REWARD_HANDOFF_CONTRACT_OK`
```

- [ ] **Step 3: Extend request-analysis docs and template with transition review**

```markdown
## Required Stages

4. Transition Safety Review Gate: declare touched transition ids or explicit `no transition impact`, record the entry/exit owner boundary, list shared state handoff risks, and map each touched transition to a runnable proof.
```

```markdown
## Transition Safety Review

- Record touched transition ids or state `no transition impact`.
- Name the transition entry owner and exit owner.
- List shared state, layout, overlay, or reparent handoff risks.
- Map each touched transition to a runner path and expected success marker.
```

- [ ] **Step 4: Tighten request-analysis-gate validation and its self-test**

```powershell
Require-MeaningfulSection $sections "Transition Safety Review" "declare touched transitions or explicit no-transition-impact coverage"
```

```powershell
$badTransition = Write-TestFile "missing-transition.md" @"
## Transition Safety Review
- transition review body intentionally omitted for failure coverage
"@
Assert-True ($badTransitionResult.Code -ne 0) "ledger without a meaningful transition review should fail"
```

- [ ] **Step 5: Update the default quality-gate ledger so the stronger request-analysis gate still passes**

```markdown
## Transition Safety Review

- no transition impact
- reason: this ledger governs broad harness aggregation and verification orchestration, not a runtime page or phase handoff implementation
```

- [ ] **Step 6: Run request-analysis verification**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-transition-safety-gate.md -Mode pre-edit`

Expected: `REQUEST_ANALYSIS_GATE_OK`

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1`

Expected: `REQUEST_ANALYSIS_GATE_TESTS_OK`

### Task 2: Transition Safety Gate and Wiring

**Files:**
- Create: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\tools\transition-safety-gate.ps1`
- Create: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\tools\transition-safety-gate.tests.ps1`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\tools\run-compile-check.ps1`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\tools\run-ltl-quality-gate.ps1`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\README.md`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\LTL-harness\00_AGENTS.md`

- [ ] **Step 1: Add the transition-safety SoT**

```markdown
## Registry

- `meta.start_flow`
  - runner: `tests/run_main_start_flow_contract.gd`
  - marker: `MAIN_START_FLOW_CONTRACT_OK`
- `page.scene_mapping`
  - runner: `tests/run_page_scene_mapping_contract.gd`
  - marker: `PAGE_SCENE_MAPPING_CONTRACT_OK`
- `reward.ceremony`
  - runner: `tests/run_reward_ceremony_contract.gd`
  - marker: `REWARD_CEREMONY_CONTRACT_OK`
- `reward.handoff`
  - runner: `tests/run_reward_handoff_contract.gd`
  - marker: `REWARD_HANDOFF_CONTRACT_OK`
```

- [ ] **Step 2: Implement the gate script with a built-in registry and hard-failure scan**

```powershell
$transitionRegistry = @{
  "meta.start_flow" = @{ Script = "tests/run_main_start_flow_contract.gd"; Marker = "MAIN_START_FLOW_CONTRACT_OK" }
  "page.scene_mapping" = @{ Script = "tests/run_page_scene_mapping_contract.gd"; Marker = "PAGE_SCENE_MAPPING_CONTRACT_OK" }
  "reward.ceremony" = @{ Script = "tests/run_reward_ceremony_contract.gd"; Marker = "REWARD_CEREMONY_CONTRACT_OK" }
  "reward.handoff" = @{ Script = "tests/run_reward_handoff_contract.gd"; Marker = "REWARD_HANDOFF_CONTRACT_OK" }
}

if ($joinedOutput -match "CrashHandlerException|signal 11|SCRIPT ERROR|Parse Error|Failed to load script") {
  $exitCode = 1
}
if (-not ($joinedOutput -match [regex]::Escape($expectedMarker))) {
  $exitCode = 1
}
```

- [ ] **Step 3: Add self-tests for no-impact, covered-impact, missing-marker, and crash-signal failure**

```powershell
$fakeRunner = Write-TestFile "tests/fake_runner_ok.ps1" 'Write-Output "REWARD_HANDOFF_CONTRACT_OK"'
$fakeCrash = Write-TestFile "tests/fake_runner_crash.ps1" 'Write-Output "signal 11"'
Assert-True ($okResult.Output -match "TRANSITION_SAFETY_GATE_OK") "covered transition should pass"
Assert-True ($crashResult.Code -ne 0) "crash string must fail the gate"
```

- [ ] **Step 4: Wire the gate into compile and quality verification**

```powershell
Write-Host "Running transition safety gate..." -ForegroundColor Cyan
$transitionGateOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $transitionGate -Root $workspace -GodotPath $godotPath -Ledger "docs/request-ledgers/2026-06-09-transition-safety-gate.md" 2>&1
```

```powershell
Invoke-NativeStep "transition safety gate" "powershell" @(
  "-NoProfile", "-ExecutionPolicy", "Bypass",
  "-File", "LTL-harness/tools/transition-safety-gate.ps1",
  "-Root", $resolvedRoot,
  "-GodotPath", $GodotPath,
  "-Ledger", $RequestLedger
) "TRANSITION_SAFETY_GATE_OK"
```

- [ ] **Step 5: Document the new blocking policy in README and AGENTS**

```markdown
- Transition-affecting work must include `Transition Safety Review` in its request ledger.
- `tools/run-compile-check.ps1` and `tools/run-ltl-quality-gate.ps1` block on `LTL-harness/tools/transition-safety-gate.ps1`.
- Exit code success is insufficient when a transition registry marker is defined.
```

- [ ] **Step 6: Run gate-specific verification**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/transition-safety-gate.tests.ps1`

Expected: `TRANSITION_SAFETY_GATE_TESTS_OK`

### Task 3: Reward Handoff Proof, Source Map, and End-to-End Verification

**Files:**
- Create: `D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL\tests\run_reward_handoff_contract.gd`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL\tests\run_main_start_flow_contract.gd`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\docs\source-map.md`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\docs\codex-worklog\history_LootingTheLeviathan_2026-06-09.md`
- Modify: `D:\Programming\ex_workspace\LootingTheLeviathan\docs\codex-worklog\complete_LootingTheLeviathan_2026-06-09.md`

- [ ] **Step 1: Normalize `run_main_start_flow_contract.gd` to marker-based success**

```gdscript
func _finish() -> void:
	if failures.is_empty():
		print("MAIN_START_FLOW_CONTRACT_OK")
		await process_frame
		quit(0)
		return
```

- [ ] **Step 2: Add a focused reward-handoff runner**

```gdscript
extends SceneTree

var failures: Array[String] = []

func _run() -> void:
	root.size = Vector2i(1440, 900)
	var MainScene = load("res://src/Main.tscn")
	var main_instance = MainScene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	# boot -> node_select -> battle clear -> reward
	# force ceremony completion callback or skip confirm path
	# assert active_page_id == "reward"
	# assert rewardPresentationStep == "tray_review"
	# assert shared backpack parent == reward workspace host
	# assert reward board + bottom row stay inside viewport
	print("REWARD_HANDOFF_CONTRACT_OK")
```

- [ ] **Step 3: Add source-map responsibilities for every new file**

```markdown
- `LTL-harness/tools/transition-safety-gate.ps1`
  - transition safety gate validates ledger handoff review and executes the registered transition proofs.
- `LTL-harness/tools/transition-safety-gate.tests.ps1`
  - transition safety gate tests cover no-impact, success-marker, and crash-string blocking behavior.
- `app-LTL/tests/run_reward_handoff_contract.gd`
  - reward handoff contract proves ceremony completion can reach tray review with the shared backpack docked and the board visible.
```

- [ ] **Step 4: Run focused reward and transition verification**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -WorkspaceRoot . -ProjectPath app-LTL -GodotPath D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe -Script tests/run_reward_handoff_contract.gd -Headless -Quit`

Expected: `REWARD_HANDOFF_CONTRACT_OK`

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/transition-safety-gate.ps1 -Root . -GodotPath D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe -Ledger docs/request-ledgers/2026-06-09-transition-safety-gate.md`

Expected: `TRANSITION_SAFETY_GATE_OK`

- [ ] **Step 5: Run compile and quality gates with the new ledger**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`

Expected: compile path prints the transition gate output and exits `0`

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-09-transition-safety-gate.md -ArtifactLedger docs/artifact-ledgers/2026-06-09-transition-safety-gate.md`

Expected: `LTL_QUALITY_GATE_OK`

- [ ] **Step 6: Record verification evidence in worklog completion notes**

```markdown
- Transition-safety gate passed with registry-backed reward handoff proof.
- Compile and quality gates now block on missing transition review, missing markers, and crash strings.
```
