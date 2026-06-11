date: 2026-06-02
task: release-blocking-gate
approval: approved

profile: release-blocking
purpose: Block removed-asset references, singleton node-map ownership drift, and other release-risk regressions while runtime-size caps are enforced by runtime-size-gate.md.

orchestrator_path: app-LTL/src/MainControllerRuntime.gd
orchestrator_threshold: 760
orchestrator_forbidden_patterns: tile_panel_nobg2, res://resources/UI/miner.png

view_path_pattern: app-LTL/src/ui/*.gd
view_threshold: 1300
view_forbidden_patterns: tile_panel_nobg2, res://resources/UI/miner.png
layout_resource_path_pattern: app-LTL/src/Main.tscn
layout_resource_threshold: 1200
layout_resource_forbidden_patterns: fit_content = true
view_dynamic_creation_paths:
strict_size_paths:

singleton_layout_owner_paths: app-LTL/src/ui/MainViewRuntime.gd, app-LTL/src/scenes/node_map/NodeMapScene.gd
singleton_layout_scan_roots: app-LTL/src
singleton_layout_forbidden_patterns: NodeMapSceneScript.new, NodeMapBackpackRow, NodeMapPage, StartColors
