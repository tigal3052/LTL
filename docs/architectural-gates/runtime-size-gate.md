date: 2026-06-11
task: runtime-size-gate
approval: approved

profile: runtime-size
purpose: Enforce 500-line active runtime source and scene files while freezing known oversized legacy owners until they are split.

strict_glob_caps: app-LTL/src/**/*.gd=500; app-LTL/src/**/*.tscn=500; app-LTL/src/ui/read_models/*.gd=300; app-LTL/src/ui/presenters/*.gd=200
legacy_debt_path_caps: app-LTL/src/ui/MainViewRuntime.gd=2429; app-LTL/src/MainControllerRuntime.gd=1667; app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd=1352; app-LTL/src/ui/RewardRevealOverlay.gd=1303; app-LTL/src/ui/ArtifactCodexPanelUI.gd=948; app-LTL/src/vocabulary/CombatVocab.gd=938; app-LTL/src/ui/BackpackUI.gd=723; app-LTL/src/ui/StatusPanelUI.gd=739
