$ErrorActionPreference = "Stop"
$godotPath = "D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe"
$workspace = "D:\Programming\ex_workspace\LootingTheLeviathan"

Write-Host "Running Godot Headless Compilation Check..." -ForegroundColor Cyan

# Run Godot headless check
$process = Start-Process -FilePath $godotPath -ArgumentList "--headless", "--path", "app-LTL", "-s", "tests/godot_contract_runner.gd" -NoNewWindow -PassThru -Wait

if ($process.ExitCode -eq 0) {
    Write-Host "Compilation Check: PASSED (GODOT_CONTRACTS_OK)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Compilation Check: FAILED" -ForegroundColor Red
    exit 1
}
