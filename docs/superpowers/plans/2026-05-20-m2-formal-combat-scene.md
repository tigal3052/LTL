# M2 Formal Combat Scene Plan

## Goal

Reconstruct M2 as a formal combat-scene slice under `app-LTL/src/**` without reviving the archived browser prototype as an implementation target.

## Path Declaration

This task may edit only `app-LTL/src/**`, `app-LTL/tests/**`, active execution-plan documents, and worklog files unless the user later approves another formal path.

## Non-Goals

- Do not edit `app-LTL/prototype/**`.
- Do not move combat rules back into DOM code or scene code.
- Do not weaken replay or headless verification to make the scene easier to ship.

## Source Inputs

- `LTL-harness/docs/11_exec-plans/01_active/08_M2_combat_scene_reconstruction.md`
- `app-LTL/src/README.md`
- `app-LTL/src/process/headless-mini-run.js`
- `app-LTL/src/phases/combat-phase.js`
- `app-LTL/src/ui/scene-read-model.js`
- `LTL-harness/docs/02_DESIGN.md`

## Implementation Slices

### Slice 1. Formal combat scene contract
- Extend the active M2 contract so the formal scene consumes only public run snapshots and combat-facing read-model fields.
- Decide which additional scene-facing fields belong in `app-LTL/src/ui/scene-read-model.js`.
- Keep queue, pin, repair, hazard, aiming, disabled, and stage-layout data as read-model output, not scene-local rule state.

### Slice 2. Input adapter boundary
- Add a formal combat input adapter under `app-LTL/src/**` that translates scene intent into existing process or phase commands.
- Ensure hold-fire, single-fire, repair intent, and disabled-state handling all flow through the same formal combat input path.
- Keep the adapter free of timing-sensitive combat rules beyond input shaping.

### Slice 3. Scene composition
- Add a formal combat scene module under `app-LTL/src/**` that renders the 7:3 layout and the 3x10 battlefield from the read model.
- Treat layout math, visibility toggles, and view labels as scene responsibilities.
- Keep terrain placement, combat status derivation, and queue semantics out of the scene module.

### Slice 4. Verification
- Add tests under `app-LTL/tests/**` for the read-model additions and input adapter behavior.
- Preserve headless verification so combat progression and replay fixtures continue to pass without the formal scene loaded.
- Add a focused layout contract test if the chosen renderer exposes deterministic battlefield geometry data.

## Recommended File Targets

- `app-LTL/src/ui/scene-read-model.js`
- `app-LTL/src/ui/` new formal combat scene module(s)
- `app-LTL/src/process/` new adapter or orchestration module if needed
- `app-LTL/src/phases/combat-phase.js` only if a formal command boundary must expand
- `app-LTL/tests/` new M2 formal scene contract tests

## Execution Order

1. Freeze the public M2 contract in tests.
2. Extend the scene read model until tests describe the missing combat-scene state.
3. Add the formal input adapter against the existing process and phase APIs.
4. Add the formal scene composition module that consumes only the read model and adapter.
5. Run headless and scene-facing tests together before closing the slice.

## Verification Commands

- `node --test app-LTL/tests/*.test.js`
- targeted `node --test` commands for new M2 tests
- `git diff -- app-LTL/prototype/browser-p0-p4`

## Done Signal

- M2 scene work lives in `app-LTL/src/**`.
- Prototype diff stays empty.
- The formal scene consumes read-model data instead of re-deriving combat rules.
- Headless and replay-oriented verification still pass without loading the scene.
