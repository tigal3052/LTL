$ErrorActionPreference = "Stop"
$godotPath = "D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe"
$workspace = "D:\Programming\ex_workspace\LootingTheLeviathan"
. (Join-Path $PSScriptRoot "godot-runner.ps1")

Write-Host "Running Godot Headless Compilation Check..." -ForegroundColor Cyan

Initialize-GodotProjectEnvironment -WorkspaceRoot $workspace -ProjectPath "app-LTL" | Out-Null

Write-Host "Running source map gate..." -ForegroundColor Cyan
$sourceMapGate = Join-Path $workspace "LTL-harness\tools\source-map-gate.ps1"
$sourceMapOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $sourceMapGate -Root $workspace 2>&1
$sourceMapExitCode = $LASTEXITCODE
$sourceMapOutput | ForEach-Object { Write-Host $_ }
if ($sourceMapExitCode -ne 0) {
    Write-Host "Source Map Gate: FAILED" -ForegroundColor Red
    exit $sourceMapExitCode
}

# Run Godot headless check directly. Editor headless mode avoids a Godot 4.3
# console crash observed during plain headless project load, and the shared
# runner keeps logs out of the project root.
$result = Invoke-GodotProjectCommand `
    -WorkspaceRoot $workspace `
    -ProjectPath "app-LTL" `
    -GodotPath $godotPath `
    -Script "tests/godot_contract_runner.gd" `
    -LogName "compile-smoke.log" `
    -Headless `
    -Editor `
    -ScriptArgs @("--smoke-only")
$output = $result.Output
$exitCode = $result.Code
$output | ForEach-Object { Write-Host $_ }

if ($result.OutputText -match "SCRIPT ERROR|Failed to load script|missing Godot formal script") {
    $exitCode = 1
}

if ($exitCode -eq 0) {
    Write-Host "Compilation Check: PASSED (GODOT_CONTRACTS_OK)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Compilation Check: FAILED" -ForegroundColor Red
    exit $exitCode
}
