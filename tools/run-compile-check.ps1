param(
    [string]$RequestLedger = "docs/request-ledgers/2026-06-02-refactor-harness-quality-gate.md"
)

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

Write-Host "Running test size gate..." -ForegroundColor Cyan
$testSizeGate = Join-Path $workspace "LTL-harness\tools\test-size-gate.ps1"
$testSizeOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $testSizeGate -Root $workspace 2>&1
$testSizeExitCode = $LASTEXITCODE
$testSizeOutput | ForEach-Object { Write-Host $_ }
if ($testSizeExitCode -ne 0) {
    Write-Host "Test Size Gate: FAILED" -ForegroundColor Red
    exit $testSizeExitCode
}

Write-Host "Running runtime size gate..." -ForegroundColor Cyan
$runtimeSizeGate = Join-Path $workspace "LTL-harness\tools\runtime-size-gate.ps1"
$runtimeSizeOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $runtimeSizeGate -Root $workspace 2>&1
$runtimeSizeExitCode = $LASTEXITCODE
$runtimeSizeOutput | ForEach-Object { Write-Host $_ }
if ($runtimeSizeExitCode -ne 0) {
    Write-Host "Runtime Size Gate: FAILED" -ForegroundColor Red
    exit $runtimeSizeExitCode
}

Write-Host "Running page contract gate..." -ForegroundColor Cyan
$pageContractGate = Join-Path $workspace "LTL-harness\tools\page-contract-gate.ps1"
$pageContractOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $pageContractGate -Root $workspace -GodotPath $godotPath 2>&1
$pageContractExitCode = $LASTEXITCODE
$pageContractOutput | ForEach-Object { Write-Host $_ }
if ($pageContractExitCode -ne 0) {
    Write-Host "Page Contract Gate: FAILED" -ForegroundColor Red
    exit $pageContractExitCode
}

Write-Host "Running transition safety gate..." -ForegroundColor Cyan
$transitionSafetyGate = Join-Path $workspace "LTL-harness\tools\transition-safety-gate.ps1"
$transitionSafetyOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $transitionSafetyGate -Root $workspace -GodotPath $godotPath -Ledger $requestLedger 2>&1
$transitionSafetyExitCode = $LASTEXITCODE
$transitionSafetyOutput | ForEach-Object { Write-Host $_ }
if ($transitionSafetyExitCode -ne 0) {
    Write-Host "Transition Safety Gate: FAILED" -ForegroundColor Red
    exit $transitionSafetyExitCode
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
