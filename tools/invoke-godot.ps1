param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$ProjectPath = "app-LTL",
  [string]$GodotPath = "D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe",
  [string]$Script = "",
  [string]$LogName = "",
  [string[]]$EngineArgs = @(),
  [string[]]$ScriptArgs = @(),
  [switch]$Headless,
  [switch]$Editor,
  [switch]$Quit
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "godot-runner.ps1")

if ([string]::IsNullOrWhiteSpace($LogName) -and -not [string]::IsNullOrWhiteSpace($Script)) {
  $LogName = [System.IO.Path]::GetFileNameWithoutExtension($Script) + ".log"
}

$result = Invoke-GodotProjectCommand `
  -WorkspaceRoot $WorkspaceRoot `
  -ProjectPath $ProjectPath `
  -GodotPath $GodotPath `
  -Script $Script `
  -LogName $LogName `
  -EngineArgs $EngineArgs `
  -ScriptArgs $ScriptArgs `
  -Headless:$Headless `
  -Editor:$Editor `
  -Quit:$Quit

$result.Output | ForEach-Object { Write-Host $_ }
exit $result.Code
