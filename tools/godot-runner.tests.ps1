$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$helperPath = Join-Path $repoRoot "tools/godot-runner.ps1"
$testRoot = Join-Path $repoRoot ".tmp-godot-runner-tests"

function Assert-True($Condition, $Message) {
  if (-not $Condition) {
    throw $Message
  }
}

function Reset-TestRoot {
  $resolvedRepo = (Resolve-Path -LiteralPath $repoRoot).Path
  $targetFull = [System.IO.Path]::GetFullPath($testRoot)
  Assert-True ($targetFull.StartsWith($resolvedRepo, [System.StringComparison]::OrdinalIgnoreCase)) "refusing to clean outside repo: $targetFull"
  if (Test-Path -LiteralPath $targetFull) {
    Remove-Item -LiteralPath $targetFull -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $targetFull | Out-Null
}

function Remove-TestRoot {
  $resolvedRepo = (Resolve-Path -LiteralPath $repoRoot).Path
  $targetFull = [System.IO.Path]::GetFullPath($testRoot)
  Assert-True ($targetFull.StartsWith($resolvedRepo, [System.StringComparison]::OrdinalIgnoreCase)) "refusing to clean outside repo: $targetFull"
  if (Test-Path -LiteralPath $targetFull) {
    Remove-Item -LiteralPath $targetFull -Recurse -Force
  }
}

Assert-True (Test-Path -LiteralPath $helperPath) "godot runner helper is missing"
. $helperPath

Reset-TestRoot

$rootName = Get-GodotManagedLogResPath -RequestedPath "reward-vfx-ui-read-models.log"
Assert-True ($rootName -eq "res://.tmp-godot-logs/reward-vfx-ui-read-models.log") "bare log names should route into .tmp-godot-logs: $rootName"

$projectRelative = Get-GodotManagedLogResPath -RequestedPath "app-LTL/tmp-slot-bg-red.log"
Assert-True ($projectRelative -eq "res://.tmp-godot-logs/tmp-slot-bg-red.log") "project-relative log paths should flatten into .tmp-godot-logs: $projectRelative"

$alreadyManaged = Get-GodotManagedLogResPath -RequestedPath "res://.tmp-godot-logs/already-managed.log"
Assert-True ($alreadyManaged -eq "res://.tmp-godot-logs/already-managed.log") "existing managed res:// log paths should stay unchanged: $alreadyManaged"

$invocationPath = Get-GodotManagedLogInvocationPath -WorkspaceRoot $testRoot -ProjectPath "app-LTL" -RequestedPath "reward-vfx-ui-read-models.log"
$expectedInvocationPath = Join-Path (Join-Path (Join-Path $testRoot "app-LTL") ".tmp-godot-logs") "reward-vfx-ui-read-models.log"
Assert-True ($invocationPath -eq $expectedInvocationPath) "invocation path should resolve to the project log directory on disk: $invocationPath"

$environment = Initialize-GodotProjectEnvironment -WorkspaceRoot $testRoot -ProjectPath "app-LTL"
Assert-True (Test-Path -LiteralPath $environment.GodotRoaming) "Initialize-GodotProjectEnvironment should create APPDATA mirror"
Assert-True (Test-Path -LiteralPath $environment.GodotLocal) "Initialize-GodotProjectEnvironment should create LOCALAPPDATA mirror"
Assert-True (Test-Path -LiteralPath $environment.LogDirectory) "Initialize-GodotProjectEnvironment should create the project log directory"
Assert-True ($environment.LogDirectory.EndsWith("app-LTL\.tmp-godot-logs")) "log directory should live under the project root: $($environment.LogDirectory)"

Remove-TestRoot
Write-Output "GODOT_RUNNER_TESTS_OK"
