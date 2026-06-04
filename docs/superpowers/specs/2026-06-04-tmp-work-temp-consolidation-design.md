# Tmp Work Temp Consolidation Design

Date: 2026-06-04
Workspace: LootingTheLeviathan
Status: Approved design for implementation planning

## Goal

Move Codex-managed temporary files and managed Godot editor/runtime temp data under one root `tmp_work/`, stop recurring empty editor folders from being recreated under `app-LTL/`, and make the preferred local launch paths explicit in code and docs.

## Problem Summary

The workspace currently accumulates temporary artifacts in multiple places:

- historical Codex temp roots such as `.tmp-*`
- Godot CLI mirrors under `.godot-user/`
- Godot logs under `app-LTL/.tmp-godot-logs/`
- recurring empty `app-LTL/export_templates/`, `app-LTL/feature_profiles/`, `app-LTL/script_templates/`, and `app-LTL/text_editor_themes/`

Current evidence points to two distinct causes:

1. Codex-managed and test-managed temp directories are under direct project control and can be moved by changing local scripts and tests.
2. The recurring empty folders under `app-LTL/` align with Godot editor data/settings concepts rather than runtime project data. The same folder classes already exist under `.godot-user/Roaming/Godot/`, and official Godot docs describe `export_templates`, `feature_profiles`, `script_templates`, and `text_editor_themes` as editor data/settings locations rather than normal runtime project folders.

This means the fix cannot rely on project cleanup alone. It must redirect the managed launch environment and only use project settings where Godot actually offers a supported override.

## Constraints

- Keep the real product surface under `app-LTL/src/**`, `app-LTL/tests/**`, and active docs untouched except where path configuration is required.
- Avoid broad runtime behavior changes unrelated to temp-path ownership.
- Preserve existing dirty-tree changes outside the temp-path scope.
- Keep the new temp layout ignorable by Git and excludable from source-map enforcement.

## Approaches Considered

### Approach A: Delete Empty Folders And Ignore Them Again

Delete the empty `app-LTL/*templates|*profiles` folders and strengthen `.gitignore`.

Pros:

- Very small code change.

Cons:

- Does not address the real recreation path.
- Folders will continue to reappear during managed or manual Godot use.
- Leaves Codex and Godot temp files fragmented across the repo.

### Approach B: Managed `tmp_work/` Root For Scripts, Tests, Logs, And Godot Launch Environment

Create one root `tmp_work/` directory, move Codex-managed temp paths there, and ensure all recommended Godot launchers set `APPDATA` and `LOCALAPPDATA` into `tmp_work/godot-user/`.

Pros:

- Solves every temp path that the repo's own scripts and Codex-managed workflows control.
- Moves editor data/settings folders out of `app-LTL/` for managed runs.
- Keeps all temporary content under one clean, ignorable root.

Cons:

- By itself, it does not address the project-specific `script_templates` search path default.
- Directly launching Godot outside the managed launcher can still bypass the new root.

### Approach C: Hybrid Managed `tmp_work/` Root Plus Project-Level Script Template Override

Use Approach B and additionally change the project-specific script-template search path so Godot no longer treats `app-LTL/script_templates/` as the preferred project-level template location.

Pros:

- Gives the strongest protection against `app-LTL/script_templates/` being recreated.
- Preserves one consolidated temp root for both managed launch data and project-scoped template lookups.
- Matches the actual split in Godot responsibilities: editor-scope folders via launch environment, project-scope template path via project settings.

Cons:

- Requires a small compatibility probe because Godot documentation confirms the path is configurable but does not clearly guarantee the exact path forms we want to use.

## Selected Approach

Approach C is the approved direction.

Implementation should treat `tmp_work/` as the only Codex-managed temp root and should use a hybrid strategy:

- environment-controlled routing for editor-scope Godot folders
- project-level override for the project-specific script template search path

## Target Layout

Create a single root folder:

- `tmp_work/`

Within it, use the following managed subtrees:

- `tmp_work/godot-user/`
  - `Local/`
  - `Roaming/`
- `tmp_work/godot-logs/`
- `tmp_work/tests/`
  - `source-map-gate/`
  - `request-analysis-gate/`
  - `godot-runner/`
- `tmp_work/project/`
  - `script_templates/`
  - other future project-scoped temp folders if needed

The implementation may create additional leaf folders inside these roots, but should not introduce new top-level temp roots outside `tmp_work/`.

## Detailed Design

### 1. Shared Temp Root Helper

Introduce one shared helper function for workspace temp ownership in the local PowerShell tooling. That helper should:

- resolve the workspace root
- return `tmp_work/` as the canonical temp root
- create any required subdirectories on demand

All currently hard-coded temp roots in repo-managed PowerShell scripts should route through this helper.

### 2. Godot Managed Environment

Update the Godot helper/runner layer so managed Godot commands use:

- `APPDATA = <workspace>/tmp_work/godot-user/Roaming`
- `LOCALAPPDATA = <workspace>/tmp_work/godot-user/Local`

This should redirect editor-scoped Godot data/settings folders such as:

- `export_templates`
- `feature_profiles`
- `script_templates`
- `text_editor_themes`

for every managed CLI or managed editor launch path.

The current managed log root should also move from `app-LTL/.tmp-godot-logs/` to `tmp_work/godot-logs/`.

### 3. Managed Editor Launcher

Add a recommended local editor launcher script so the documented GUI path also uses the managed `tmp_work/` environment.

This launcher should:

- prepare `tmp_work/godot-user/...`
- start the Godot editor executable with `--path app-LTL`
- clearly document that direct manual launching of the editor binary may bypass the temp-root policy

This is necessary because project settings alone cannot relocate editor-scope folders like `export_templates` or `text_editor_themes`.

### 4. Project-Level Script Template Path

Change the project-specific script-template search path away from the default `res://script_templates`.

Preferred implementation target:

- point the project setting at a path rooted under `tmp_work/project/script_templates`

Compatibility rule:

- first verify whether Godot accepts the chosen non-default path form in this project context
- if the preferred form is rejected, use the closest supported fallback that still avoids `app-LTL/script_templates/` recreation during managed runs

The fallback should still preserve the main design goal: Codex-managed script-template work must live under `tmp_work/`, not under `app-LTL/`.

### 5. Test Temp Roots

Move existing test-only temp roots into `tmp_work/tests/...`.

This includes the current equivalents of:

- `.tmp-source-map-gate-tests`
- `.tmp-request-analysis-gate-tests`
- `.tmp-godot-runner-tests`

Tests should continue to defend against writing outside the repo, but their safety boundary should now be "`tmp_work/tests/...` stays inside the workspace root."

### 6. Git Ignore And Source-Map Policy

Update `.gitignore` and source-map gate exclusions so `tmp_work/` is treated as the canonical ignored temp root.

This should replace the current pattern of accumulating new one-off temp-root exclusions over time.

### 7. Cleanup Policy

After the new managed paths are in place:

- remove the currently empty duplicate folders under `app-LTL/`
- verify that managed headless runs and managed editor launch paths do not recreate them

If a folder still reappears only when bypassing the managed launcher, document that behavior explicitly instead of overfitting project code around an unmanaged launch path.

## Data Flow

### Managed Headless Run

1. PowerShell helper resolves workspace temp root.
2. Helper creates `tmp_work/godot-user/...` and `tmp_work/godot-logs/`.
3. Helper sets `APPDATA` and `LOCALAPPDATA`.
4. Godot command runs against `app-LTL`.
5. Logs and editor-managed side effects land under `tmp_work/`, not under `app-LTL/`.

### Managed GUI Editor Run

1. Local launcher resolves `tmp_work/`.
2. Launcher prepares Godot user-data mirrors inside `tmp_work/godot-user/...`.
3. Launcher starts Godot editor for `app-LTL`.
4. Editor-scoped folders are created under the managed Godot user-data mirror instead of beside project files.

### Project Script Template Lookup

1. Godot reads the project-specific template search-path setting.
2. Project-defined templates are searched in the managed non-default location.
3. `app-LTL/script_templates/` is no longer the preferred project-defined template target.

## Error Handling

- If the preferred project template path form is not accepted by Godot, fail the compatibility probe clearly and switch to the documented fallback instead of silently restoring `app-LTL/script_templates/`.
- If a managed launcher cannot create its `tmp_work/` subdirectories, the script should fail fast with a message that identifies the missing temp subtree.
- If direct editor launches still recreate folders under `app-LTL/`, treat that as a documentation/enforcement issue, not as evidence that the managed path migration failed.

## Verification Plan

- Add or update focused PowerShell tests for the shared temp-root helper.
- Verify the Godot runner tests now create temp assets under `tmp_work/`.
- Run source-map gate after path updates.
- Run at least one managed Godot headless command and confirm:
  - logs land under `tmp_work/godot-logs/`
  - Godot user folders land under `tmp_work/godot-user/`
  - the duplicate empty folders under `app-LTL/` do not return
- If a GUI launcher is added, perform a manual spot-check that its first launch writes into `tmp_work/godot-user/`.

## Non-Goals

- Eliminating all possible Godot-generated folders for every imaginable unmanaged launch path.
- Refactoring unrelated gameplay code or test expectations.
- Reorganizing permanent runtime assets or product docs into `tmp_work/`.

## References

- Godot file/data path docs: editor data/settings and self-contained mode overview
  - https://docs.godotengine.org/en/4.1/tutorials/io/data_paths.html
- Godot project settings docs: custom user-dir behavior
  - https://docs.godotengine.org/en/stable/classes/class_projectsettings.html
- Godot script template docs: configurable project template search path
  - https://docs.godotengine.org/en/4.4/tutorials/scripting/creating_script_templates.html
