date: 2026-06-11
task: runtime-size-gate
approval: approved

profile: runtime-size
purpose: Freeze the real active runtime owners near the current baseline and keep extracted runtime leaves within a few hundred lines.

strict_path_caps: app-LTL/src/MainControllerRuntime.gd=1700; app-LTL/src/ui/MainViewRuntime.gd=2550; app-LTL/src/scenes/node_map/NodeMapScene.gd=780; app-LTL/src/ui/RewardRevealOverlay.gd=1360; app-LTL/src/ui/ArtifactCodexPanelUI.gd=980; app-LTL/src/ui/BackpackUI.gd=760; app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd=1400
strict_glob_caps: app-LTL/src/ui/*.gd=500; app-LTL/src/scenes/pages/*.gd=600; app-LTL/src/ui/read_models/*.gd=300; app-LTL/src/ui/presenters/*.gd=200
