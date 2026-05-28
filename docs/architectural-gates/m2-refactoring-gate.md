date: 2026-05-26
task: m2-refactoring-gate
approval: approved

orchestrator_path: app-LTL/src/MainController.gd
orchestrator_threshold: 180
orchestrator_forbidden_patterns: _draw_resonance_beam, _spawn_hit_particles, _setup_backpack_grid_slots, run.state[, pendingRewards, claim_reward_effect, purchase_passive

view_path_pattern: app-LTL/src/ui/*UI.gd
view_threshold: 150
view_forbidden_patterns: CombatScenePreviewController, HeadlessMiniRun, CombatSimulator, Button.new, PanelContainer.new, AudioStreamWAV.new
view_dynamic_creation_paths: app-LTL/src/ui/ShopPanelUI.gd, app-LTL/src/ui/ArtifactTooltipUI.gd, app-LTL/src/ui/GiantTimerUI.gd
strict_size_paths: app-LTL/src/MainController.gd, app-LTL/src/ui/MainUI.gd
