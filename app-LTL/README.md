# Looting The Leviathan

This app is now a Godot 4.3 project. The formal M0/M1/M2 implementation lives in
`res://src/**` as GDScript, and the archived prototype folders under
`res://prototype/**` are reference material only.

## Runtime

- Engine: Godot 4.3
- Language: GDScript
- Main scene: `res://src/Main.tscn`
- Formal contracts and runtime:
  - `src/domain/FormalContracts.gd`
  - `src/process/HeadlessMiniRun.gd`
  - `src/process/CombatInputAdapter.gd`
  - `src/process/ReplayProcess.gd`
  - `src/ui/SceneReadModel.gd`
  - `src/ui/CombatSceneModel.gd`
  - `src/ui/CombatScenePreviewController.gd`

## Verification

Run the formal M1/M2 contract suite:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script tests/godot_contract_runner.gd --quit
```

Run the replay smoke check:

```powershell
& 'D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe' --headless --path 'D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL' --script src/tools/FormalReplayRunner.gd --quit
```

Expected contract output includes `GODOT_CONTRACTS_OK`. Expected replay output has
`"phase": "run_complete"` and `"runComplete": true`.

## Boundary

Do not add new runtime code under `prototype/**`. Future milestones should extend
the formal Godot path under `src/**` and add Godot-facing tests under `tests/**`.
