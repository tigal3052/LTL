# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-29

## Active Work

Fix combat feel QA issues: smooth artifact cooldown charge animation, improve system log readability inside parchment, and implement the four energy-color combat effects from the Godot TDD plan.

## Request Summary

- Cooldown fill currently steps once per combat tick instead of visually interpolating smoothly.
- System log text has poor contrast/size and does not sit cleanly inside the parchment panel.
- Red, blue, green, and purple energy rules are incomplete; green must damage health through shields and purple must apply a terrain debuff.

## Scope

- Add regression tests for green shield-piercing health damage, red/blue damage emphasis, and purple terrain debuff metadata.
- Update `CombatVocab` damage resolution to use explicit per-color shield/health rules.
- Add a UI-side smooth cooldown fill display that interpolates between model tick snapshots.
- Restyle `LogConsoleUI` and relevant scene settings for smaller, higher-contrast parchment-contained text.

## Out of Scope

- No full balance pass beyond the requested color identity rules.
- No new art assets for the parchment panel.
- No broader combat node generation redesign.

## Steps

- Write failing combat/color-rule and cooldown-ratio tests.
- Implement combat resolver changes and terrain debuff projection.
- Implement cooldown overlay interpolation in backpack UI.
- Adjust system log margins/font color/font size.
- Run Godot contract checks, i18n gate if text keys change, and `git diff --check`.

## Expected Outputs

- Smooth visual cooldown fill.
- More readable system log text inside the parchment area.
- Color-specific combat rules with test coverage.
- Updated worklog and verification notes.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `git diff --check`

## Plan Change Log

- 2026-05-29: Worklog bootstrapped automatically by Codex hook.
