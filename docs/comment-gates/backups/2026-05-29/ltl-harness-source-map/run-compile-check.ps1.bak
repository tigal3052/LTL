$ErrorActionPreference = "Stop"
$godotPath = "D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe"
$workspace = "D:\Programming\ex_workspace\LootingTheLeviathan"
$godotUserRoot = Join-Path $workspace ".godot-user"
$godotRoaming = Join-Path $godotUserRoot "Roaming"
$godotLocal = Join-Path $godotUserRoot "Local"

Write-Host "Running Godot Headless Compilation Check..." -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $godotRoaming, $godotLocal | Out-Null
$env:APPDATA = $godotRoaming
$env:LOCALAPPDATA = $godotLocal

# Run Godot headless check directly. Start-Process can fail on Windows when the
# inherited environment contains both Path and PATH keys. Editor headless mode
# avoids a Godot 4.3 console crash observed during plain headless project load.
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$output = & $godotPath --headless --editor --path "app-LTL" -s "tests/godot_contract_runner.gd" -- --smoke-only 2>&1
$ErrorActionPreference = $previousErrorActionPreference
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Host $_ }

if ($output -match "SCRIPT ERROR|Failed to load script|missing Godot formal script") {
    $exitCode = 1
}

if ($exitCode -eq 0) {
    Write-Host "Compilation Check: PASSED (GODOT_CONTRACTS_OK)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Compilation Check: FAILED" -ForegroundColor Red
    exit $exitCode
}
