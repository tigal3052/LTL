date: 2026-05-26
task: m2-refactoring-gate
approval: approved

orchestrator_path: app-LTL/src/MainController.gd
orchestrator_threshold: 200
orchestrator_forbidden_patterns: _draw_resonance_beam, _spawn_hit_particles, _setup_backpack_grid_slots

view_path_pattern: app-LTL/src/ui/*UI.gd
view_threshold: 100
view_forbidden_patterns: CombatScenePreviewController, HeadlessMiniRun, CombatSimulator
