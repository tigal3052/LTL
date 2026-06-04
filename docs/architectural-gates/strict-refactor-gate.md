date: 2026-06-02
task: strict-refactor-gate
approval: approved

profile: strict-refactor
purpose: Block regression in newly extracted policy presenters that should stay pure and compact.

orchestrator_path: app-LTL/src/ui/presenters/RewardCeremonyPolicy.gd
orchestrator_threshold: 80
orchestrator_forbidden_patterns: extends Control, get_tree(, add_child, Button.new, PanelContainer.new, AudioStreamWAV.new

view_path_pattern: app-LTL/src/ui/presenters/*Policy.gd
view_threshold: 120
view_forbidden_patterns: extends Control, get_tree(, add_child, Button.new, PanelContainer.new, AudioStreamWAV.new
view_dynamic_creation_paths:
strict_size_paths: app-LTL/src/ui/presenters/RewardCeremonyPolicy.gd, app-LTL/src/ui/presenters/BackpackPinLayoutPolicy.gd
