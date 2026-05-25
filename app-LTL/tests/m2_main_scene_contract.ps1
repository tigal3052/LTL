$ErrorActionPreference = "Stop"

$mainController = Get-Content "app-LTL/src/MainController.gd" -Raw
$mainScene = Get-Content "app-LTL/src/Main.tscn" -Raw

$failures = @()

if ($mainController -match "JSON\.stringify") {
    $failures += "MainController.gd still dumps JSON text instead of rendering UI."
}

if ($mainController -match "\bString\(") {
    $failures += "MainController.gd still uses String(...) constructor-style coercion; use str(...) for Godot-safe string conversion."
}

foreach ($requiredMethod in @(
    "func _render_scene",
    "func _render_battlefield",
    "func _on_reset_pressed",
    "func _on_start_pressed",
    "func _on_hold_fire_pressed",
    "func _on_repair_pressed",
    "func _on_claim_rewards_pressed"
)) {
    if (-not $mainController.Contains($requiredMethod)) {
        $failures += "Missing controller render/action method: $requiredMethod"
    }
}

foreach ($requiredNode in @(
    'node name="PhaseLabel"',
    'node name="StageLabel"',
    'node name="NodeSelectPanel"',
    'node name="BattlefieldGrid"',
    'node name="RewardPanel"',
    'node name="ActionBar"'
)) {
    if (-not $mainScene.Contains($requiredNode)) {
        $failures += "Main.tscn is missing required preview node marker: $requiredNode"
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "M2_MAIN_SCENE_CONTRACT_OK"
