# watch-compile.ps1
# watches app-LTL directory for any .gd or .tscn file changes and automatically triggers the Godot headless compilation runner.
$ErrorActionPreference = "Continue"

$workspace = "D:\Programming\ex_workspace\LootingTheLeviathan"
$path = Join-Path $workspace "app-LTL"
$godotPath = "D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $path
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Track last write time to prevent duplicate triggers from quick succession writes
$lastTriggered = [DateTime]::MinValue
$cooldown = [TimeSpan]::FromMilliseconds(500)

$runCheck = {
    param($fullPath, $changeType)
    
    # Check if file has correct extension
    if ($fullPath -notmatch '\.(gd|tscn)$') {
        return
    }
    
    $now = [DateTime]::Now
    if (($now - $lastTriggered) -lt $cooldown) {
        return
    }
    $script:lastTriggered = $now
    
    Clear-Host
    Write-Host "[Auto-Watch] File changed: $fullPath ($changeType)" -ForegroundColor Cyan
    Write-Host "Triggering Godot Headless compilation check..." -ForegroundColor Cyan
    
    $process = Start-Process -FilePath $godotPath -ArgumentList "--headless", "--path", "app-LTL", "-s", "tests/godot_contract_runner.gd" -NoNewWindow -PassThru -Wait
    
    if ($process.ExitCode -eq 0) {
        Write-Host "=============================" -ForegroundColor Green
        Write-Host "Compilation Check: PASSED :)" -ForegroundColor Green
        Write-Host "=============================" -ForegroundColor Green
    } else {
        Write-Host "=============================" -ForegroundColor Red
        Write-Host "Compilation Check: FAILED :(" -ForegroundColor Red
        Write-Host "=============================" -ForegroundColor Red
    }
}

# Bind events
$onChanged = Register-ObjectEvent $watcher "Changed" -Action {
    $runCheck.Invoke($Event.SourceEventArgs.FullPath, $Event.SourceEventArgs.ChangeType)
}
$onCreated = Register-ObjectEvent $watcher "Created" -Action {
    $runCheck.Invoke($Event.SourceEventArgs.FullPath, $Event.SourceEventArgs.ChangeType)
}

Write-Host "Watching GDScript & TSCN changes under: $path" -ForegroundColor Yellow
Write-Host "Keep this window open. Press Ctrl+C to terminate the watch loop." -ForegroundColor Yellow
Write-Host "Initial compilation check running..." -ForegroundColor Gray
$process = Start-Process -FilePath $godotPath -ArgumentList "--headless", "--path", "app-LTL", "-s", "tests/godot_contract_runner.gd" -NoNewWindow -PassThru -Wait

if ($process.ExitCode -eq 0) {
    Write-Host "Initial Check: PASSED" -ForegroundColor Green
} else {
    Write-Host "Initial Check: FAILED" -ForegroundColor Red
}

try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    # Cleanup watcher events on exit
    Unregister-Event -SourceIdentifier $onChanged.SourceIdentifier -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $onCreated.SourceIdentifier -ErrorAction SilentlyContinue
    $watcher.Dispose()
    Write-Host "Watcher stopped and resources cleaned up." -ForegroundColor Gray
}
