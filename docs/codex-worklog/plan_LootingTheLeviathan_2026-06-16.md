# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-16

## Active Work

Mark the current M7 implementation bundle complete, verify it, commit it, and
push `codex/m4-m9-release-quality-implementation` to origin.

## Request Summary

The user asked to mark the current M7 implementation complete, commit the
current bundle, and push it to git. Earlier M7 implementation and follow-up
work is already recorded in this dated plan; this active request is the final
status/documentation handoff and git publish step for the current dirty tree.

## Scope

- Mark the M7 replan checklist as completed based on the already-recorded
  implementation and verification evidence.
- Keep manual M7 signoff items unchecked unless they require and receive fresh
  human/player QA evidence.
- Update today's worklog history/completion for this commit-and-push handoff.
- Run the available compile/quality gates and record exact verification results
  before committing.
- Stage, commit, and push the current M7-related bundle on the active branch.
- Mutable completion-status files:
  `docs/superpowers/plans/2026-06-13-m7-narrative-integration-replan.ko.md`,
  `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-16.md`,
  `docs/codex-worklog/history_LootingTheLeviathan_2026-06-16.md`, and
  `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-16.md`.

## Out Of Scope

- Additional gameplay, UI, story, reward, narrative, or harness behavior changes.
- Manual QA signoff without fresh human/player evidence.
- PR creation, branch switching, merge, force push, reset, or discard.
- Reverting user or earlier agent changes in the current dirty tree.

## Steps

- Inspect the dirty tree and confirm the bundle is M7/follow-up related.
- Update M7 completion/status docs with minimal edits.
- Run `tools/run-compile-check.ps1`, `tools/run-ltl-quality-gate.ps1`, and
  `git diff --check`.
- Stage the intended bundle, create a git commit, and push the current branch.
- Record the completion outcome and remaining unverified areas honestly.

## Expected Outputs

- M7 plan/worklog documents no longer describe the already-completed
  implementation as pending.
- A new commit on `codex/m4-m9-release-quality-implementation`.
- The active branch pushed to `origin/codex/m4-m9-release-quality-implementation`.
- Manual signoff gaps remain visible rather than being silently checked off.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-16-m7-narrative-integration.md`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-16-m7-narrative-integration.md`
- `git diff --check`

## Plan Change Log

- 2026-06-16: Replaced the reward-drop regression plan with the user's requested
  checkpoint, M6 completion, and M7 narrative integration plan. Checkpoint commit
  `d02e6e0` was pushed before this plan update.
- 2026-06-16: M7 implementation reached green verification; final step is to
  commit and push the M7 implementation bundle.
- 2026-06-16: Added a follow-up reporting task to summarize the completed M7
  narrative integration and rewrite the manual signoff checklist in plain Korean.
  Scope is read-only for game code; only worklog reporting files may be updated.
- 2026-06-16: Added a follow-up M7 narrative gating bugfix scope for immediate
  battle/reward guide toasts, input blocking until dismissal, and the English
  settings apply-and-close freeze.
- 2026-06-16: Switched top-level active work to the user's current completion
  request: mark M7 complete, verify, commit, and push the branch.

## Active Work Update - M7 Narrative Start Prompt Follow-up

### Request summary

The user reported that the M7 intro narrative text (`LTL은 레비아탄을 사냥하지 않는다...`)
is visually covering the start screen and does not make click/next progression
discoverable. If this is the story surface, it needs a visible prompt such as
`진행하려면 클릭해주세요`, a recognizable next/continue icon, a central or lower
dialogue area, and an upper image area.

### Scope

- Keep the M7 narrative capsule, shown-once history, telemetry, and page flow
  boundaries intact.
- Update the narrative runtime surface so the intro text reads as a story/dialogue
  panel instead of an indefinite caption/toast.
- Add a visible continue prompt and icon/signifier.
- Add focused contract coverage for the narrative prompt/layout/dismiss affordance.

### Out of scope

- Reworking character select, node select routing, reward, combat, or backpack
  behavior.
- Replacing the narrative data/history/selection capsule.
- Adding new production art assets unless the existing code can reference them
  without broad asset pipeline work.

### Steps

- Inspect current narrative render wiring and existing start-gate tests.
- Add RED contract coverage for dialogue area, visual area, continue prompt/icon,
  and skip affordance.
- Implement the minimal narrative surface changes in the existing
  `NarrativeToast`/main-view wiring.
- Run focused Godot contract checks and compile/quality checks where feasible.
- Record history and completion outcomes.

### Expected outputs

- First M7 narrative appears as a structured story panel with a top visual area
  and lower/central dialogue area.
- A corner prompt plus visible next icon tells the player how to continue.
- Click/confirm input can dismiss the narrative surface without changing unrelated
  page transitions.

### Verification method

- RED/GREEN focused Godot contract around first narrative surface behavior.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `git diff --check`

## Active Work Update - M7 Battle/Reward Guide Gating and English Apply Fix

### Request summary

The user reported three follow-up runtime issues: the combat guide toast only
appears after striking terrain, reward guidance appears too late after reward
interaction has begun, and selecting English in settings then pressing apply
and close freezes the game.

### Scope

- Ensure the combat guide narrative is selected and rendered immediately on
  combat entry before the player can start attacking.
- Gate combat interactions while a blocking guide narrative is visible, then
  resume input after the player continues.
- Ensure the reward guide narrative appears before reward selection/manipulation
  and blocks reward item handling until dismissal.
- Diagnose and fix the English apply-and-close freeze without disabling
  localization or settings persistence.
- Preserve the newly structured story surface layout and existing M7 narrative
  seen/history behavior.

### Out of scope

- Redesigning combat, reward, backpack, or settings screens beyond the requested
  gating/freeze fixes.
- Replacing the M7 narrative data/history capsule.
- Reverting unrelated user or prior-session changes.

### Steps

- Inspect narrative selection, combat entry, reward tray, and settings locale
  application paths.
- Add or update focused contract coverage that reproduces the delayed combat
  toast, delayed reward toast, and English apply-and-close freeze.
- Implement the smallest controller/view gating changes required for blocking
  guide toasts and dismissal-driven resume.
- Implement the English locale apply fix once the freeze path is isolated.
- Run focused tests plus compile/diff checks and document residual warnings.

### Expected outputs

- Combat entry displays guide toast immediately and ignores battle actions until
  the toast is continued.
- Reward tray displays guide toast before reward item actions and ignores those
  actions until the toast is continued.
- Settings English apply-and-close completes and returns to interactive UI.

### Verification method

- RED/GREEN focused Godot contract coverage for combat/reward narrative gating.
- Focused settings language apply-and-close contract or smoke test.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `git diff --check`

## Active Work Update - Hybrid Story Presentation Implementation

### Request summary

The user approved implementation of the hybrid story presentation plan: normal
story should move to a dedicated Full VN-style page, while in-run guidance and
boss/story callouts should stay on the existing narrative toast surface with
stronger positioning and character/visual support.

### Scope

- Add a separate story scene content table and release-content validation.
- Add story model/history/selection/read-model/runtime-page support.
- Register a `story_scene` meta page and route the first safe intro story into
  it after character selection, returning to the intended page afterward.
- Keep short in-game narrative beats in `narrative-beats.json`, extending them
  with toast anchor, variant, portrait, and visual metadata.
- Enhance `NarrativeToast` rendering and layout without removing current toast
  behavior or changing combat/reward/node reducer results.
- Add focused contract tests for story scene selection/history/projection and
  toast metadata/read-model projection.

### Out of scope

- Live2D, voice playback, complex branching choices, or a full story archive.
- Rewriting unrelated character, leviathan, node, combat, reward, or backpack
  pages beyond the minimum page registration and routing hooks.
- Reverting existing uncommitted M7 narrative follow-up work.

### Steps

- Review current dirty M7 narrative state and preserve unrelated changes.
- Add RED tests for `storyScenes` data shape, story shown-once history, story
  selection purity, return-page behavior, and toast visual metadata projection.
- Implement the smallest story data/model/history/selection/read-model/page
  stack needed for an intro VN scene.
- Wire `story_scene` into page registration, layout presentation, controller
  story routing, and continue/skip completion.
- Extend narrative toast metadata projection, rendering, and anchor layout.
- Run focused Godot contracts, compile checks, quality gate where feasible, and
  `git diff --check`.

### Expected outputs

- A first-run intro story can display as a dedicated VN-style page with
  background, two-dimensional portrait area, dialogue text, continue, and skip.
- Story seen state is recorded in `storySeenSceneIds`, separate from
  `narrativeSeenBeatIds`.
- Existing narrative toasts remain available for battle/reward/clear guidance
  and can carry anchor/portrait/variant metadata.
- Existing reducer results, reward ceremony gating, and in-run interaction rules
  are preserved.

### Verification method

- RED/GREEN focused story and narrative contract tests.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1`
- `git diff --check`

## Active Work Update - Reward Ceremony Count Auto-Advance

### Request summary

The user reported that, after combat, the reward reveal ceremony pauses after
the lid-opening/count-tease beat and requires a click before the item-count
burst appears. The requested change is for the lid-opening beat to flow
automatically into the item-count burst without requiring a click.

### Scope

- Preserve the existing reward reveal sequence:
  `count_tease -> count_lock -> reveal_queue -> tray_review`.
- Change only the transition from `count_tease` to `count_lock` so it advances
  automatically when the count-tease animation completes.
- Keep later reveal/card information steps confirm-gated unless existing tests
  require otherwise.
- Add focused contract coverage for the auto-advance behavior.

### Out of scope

- Reward roll data, reward tray claim logic, backpack placement, card content,
  and post-ceremony reward-list behavior.
- Broad UI redesign, timing retuning beyond the requested transition, or
  unrelated M7 narrative/story work.

### Steps

- Inspect the reward ceremony overlay and existing reward ceremony contract
  tests.
- Add a RED contract proving `count_tease` completes into `count_lock` without
  confirm input.
- Implement the smallest state-transition change in `RewardRevealOverlay`.
- Run the focused reward ceremony contract and record verification results.

### Expected outputs

- The lid-opening/count-tease beat automatically enters the item-count burst.
- Later reward reveal steps still wait for confirmation after becoming readable.
- Focused contract coverage documents the behavior.

### Verification method

- RED/GREEN: reward ceremony Godot contract.
- `git diff --check`

## Active Work Update - M7 Completion Commit and Push

### Request summary

The user asked to mark the current M7 implementation complete, commit it, and
push it to git.

### Scope

- Mark the M7 replan checklist as completed where the implementation and
  recorded verification have already satisfied the plan.
- Keep manual signoff items that still require human visual review unchecked.
- Update today's worklog history/completion for this commit-and-push handoff.
- Verify the current bundle before committing and pushing the active branch.

### Out of scope

- Additional gameplay, UI, story, reward, or narrative behavior changes.
- Manual QA signoff without fresh human/player evidence.
- PR creation, branch switching, merge, force push, or reset.

### Steps

- Inspect the current dirty tree and confirm the changes are M7-related.
- Update M7 completion/status docs with minimal edits.
- Run focused/broad verification appropriate for the current M7 bundle.
- Stage the intended bundle, create a git commit, and push the current branch.

### Expected outputs

- M7 plan/worklog documents no longer describe the already-completed
  implementation as pending.
- A new commit on `codex/m4-m9-release-quality-implementation`.
- The branch pushed to `origin/codex/m4-m9-release-quality-implementation`.

### Verification method

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-16-m7-narrative-integration.md`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-16-m7-narrative-integration.md`
- `git diff --check`

## Active Work Update - Generic Harness Process Promotion

### Request summary

The user asked to compare the reusable `D:\Programming\ex_workspace\agent-harness`
with the LTL-specific `LTL-harness`, identify meaningful process, methodology,
gate, and testing improvements proven in the LTL harness, generalize them, and
reflect the reusable portions back into the generic harness for all projects.

### Scope

- Compare generic and LTL harness documents, templates, and gate scripts.
- Preserve LTL-specific project rules as child-harness examples rather than
  copying them into the generic harness.
- Promote only general harness patterns such as request source-map lookup,
  root-cause ledgers, transition/handoff verification, feature-unit lifecycle
  planning, runtime-size budgeting, performance review, and resolution proof.
- Keep unrelated LTL app source and existing dirty workspace changes untouched.

### Out of scope

- Modifying `app-LTL/src/**`, `app-LTL/tests/**`, narrative data, or UI work.
- Reverting any existing user or prior-session changes.
- Copying Godot/LTL-specific paths, markers, or runner assumptions into the
  generic harness without parameterization.

### Steps

- Inspect both harness file maps, entry documents, request ledger templates, and
  gate scripts.
- Present the generalization design and get approval before harness edits.
- Update the generic harness documents/templates/scripts within the approved
  scope.
- Run focused gate self-tests and source-map/request-analysis verification where
  feasible.

### Expected outputs

- A concise analysis of reusable LTL harness practices.
- Generic harness updates that express those practices without LTL coupling.
- Updated worklog and completion evidence describing verification and any
  residual gaps.

### Verification method

- Generic request-analysis gate self-tests.
- Generic source-map gate after file map updates.
- Any new or changed generic gate self-tests.
- `git diff --check` in the affected harness where feasible.

## Active Work Update - Current M7 Completion Commit and Push

### Request summary

The user asked to mark the current M7 implementation complete, commit it, and
push the active branch to git.

### Scope

- Mark M7 implementation/status docs complete based on recorded implementation
  and verification evidence.
- Preserve manual signoff items that still need human/player QA.
- Run fresh verification before completion claims.
- Commit and push only the current intended M7/follow-up bundle.

### Out of scope

- Additional behavior changes.
- Manual QA signoff without fresh manual evidence.
- PR creation, branch switching, merge, force push, reset, discard, or unrelated
  cleanup.

### Steps

- Finish minimal M7 completion-status doc edits.
- Run compile check, quality gate, and diff whitespace verification.
- Review the staged scope.
- Commit and push `codex/m4-m9-release-quality-implementation`.
- Record completion results.

### Expected outputs

- M7 plan/worklog status reflects completion rather than pending work.
- One new git commit for the current bundle.
- Current branch pushed to origin.

### Verification method

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-16-m7-narrative-integration.md`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-16-m7-narrative-integration.md`
- `git diff --check`
