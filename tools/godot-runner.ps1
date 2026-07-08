function Get-DefaultGodotConsolePath {
  return "D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe"
}

function Resolve-GodotRunnerPath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    throw "path is required"
  }
  return [System.IO.Path]::GetFullPath($Path).TrimEnd("\", "/")
}

function Resolve-GodotProjectRoot {
  param(
    [string]$WorkspaceRoot,
    [string]$ProjectPath = "app-LTL"
  )

  $resolvedWorkspace = Resolve-GodotRunnerPath $WorkspaceRoot
  if ([System.IO.Path]::IsPathRooted($ProjectPath)) {
    return Resolve-GodotRunnerPath $ProjectPath
  }
  return Resolve-GodotRunnerPath (Join-Path $resolvedWorkspace $ProjectPath)
}

function Get-GodotManagedLogLeaf {
  param([string]$RequestedPath)

  $candidate = if ([string]::IsNullOrWhiteSpace($RequestedPath)) {
    "godot.log"
  } else {
    Split-Path -Leaf ($RequestedPath -replace "^res://", "" -replace "^user://", "")
  }
  if ([string]::IsNullOrWhiteSpace($candidate)) {
    $candidate = "godot.log"
  }
  if ($candidate -notmatch "\.[A-Za-z0-9]+$") {
    $candidate += ".log"
  }
  return ($candidate -replace "[^A-Za-z0-9_.-]+", "-").Trim("-")
}

function Get-GodotManagedLogResPath {
  param([string]$RequestedPath)

  if ($RequestedPath -like "user://*") {
    return $RequestedPath
  }
  if ($RequestedPath -like "res://.tmp-godot-logs/*") {
    return $RequestedPath
  }
  $leaf = Get-GodotManagedLogLeaf -RequestedPath $RequestedPath
  return "res://.tmp-godot-logs/$leaf"
}

function Convert-GodotResPathToFilesystemPath {
  param(
    [string]$ProjectRoot,
    [string]$ResPath
  )

  if ([string]::IsNullOrWhiteSpace($ResPath)) {
    return ""
  }
  if ($ResPath -like "res://*") {
    $relative = $ResPath.Substring(6) -replace "/", [System.IO.Path]::DirectorySeparatorChar
    return Join-Path (Resolve-GodotRunnerPath $ProjectRoot) $relative
  }
  return $ResPath
}

function Get-GodotManagedLogInvocationPath {
  param(
    [string]$WorkspaceRoot,
    [string]$ProjectPath = "app-LTL",
    [string]$RequestedPath
  )

  $projectRoot = Resolve-GodotProjectRoot -WorkspaceRoot $WorkspaceRoot -ProjectPath $ProjectPath
  $managedLogResPath = Get-GodotManagedLogResPath -RequestedPath $RequestedPath
  return Convert-GodotResPathToFilesystemPath -ProjectRoot $projectRoot -ResPath $managedLogResPath
}

function Initialize-GodotProjectEnvironment {
  param(
    [string]$WorkspaceRoot,
    [string]$ProjectPath = "app-LTL"
  )

  $resolvedWorkspace = Resolve-GodotRunnerPath $WorkspaceRoot
  $projectRoot = Resolve-GodotProjectRoot -WorkspaceRoot $resolvedWorkspace -ProjectPath $ProjectPath
  $godotUserRoot = Join-Path $resolvedWorkspace ".godot-user"
  $godotRoaming = Join-Path $godotUserRoot "Roaming"
  $godotLocal = Join-Path $godotUserRoot "Local"
  $logDirectory = Join-Path $projectRoot ".tmp-godot-logs"
  New-Item -ItemType Directory -Force -Path $godotRoaming, $godotLocal, $logDirectory | Out-Null
  $env:APPDATA = $godotRoaming
  $env:LOCALAPPDATA = $godotLocal
  return [PSCustomObject]@{
    WorkspaceRoot = $resolvedWorkspace
    ProjectRoot = $projectRoot
    GodotUserRoot = $godotUserRoot
    GodotRoaming = $godotRoaming
    GodotLocal = $godotLocal
    LogDirectory = $logDirectory
  }
}

function Invoke-GodotProjectCommand {
  param(
    [string]$WorkspaceRoot,
    [string]$ProjectPath = "app-LTL",
    [string]$GodotPath = (Get-DefaultGodotConsolePath),
    [string]$Script = "",
    [string]$LogName = "",
    [string[]]$EngineArgs = @(),
    [string[]]$ScriptArgs = @(),
    [switch]$Headless,
    [switch]$Editor,
    [switch]$Quit
  )

  if (-not $Headless.IsPresent -and -not $Editor.IsPresent) {
    $Headless = $true
  }

  $environment = Initialize-GodotProjectEnvironment -WorkspaceRoot $WorkspaceRoot -ProjectPath $ProjectPath
  $managedLogResPath = Get-GodotManagedLogResPath -RequestedPath $LogName
  $managedLogInvocationPath = Get-GodotManagedLogInvocationPath -WorkspaceRoot $environment.WorkspaceRoot -ProjectPath $ProjectPath -RequestedPath $LogName

  $arguments = @()
  if ($Headless.IsPresent) {
    $arguments += "--headless"
  }
  if ($Editor.IsPresent) {
    $arguments += "--editor"
  }
  $arguments += @("--path", $environment.ProjectRoot)
  if ($EngineArgs.Count -gt 0) {
    $arguments += $EngineArgs
  }
  if (-not [string]::IsNullOrWhiteSpace($managedLogInvocationPath)) {
    $arguments += @("--log-file", $managedLogInvocationPath)
  }
  if (-not [string]::IsNullOrWhiteSpace($Script)) {
    $arguments += @("--script", $Script)
  }
  if ($Quit.IsPresent) {
    $arguments += "--quit"
  }
  if ($ScriptArgs.Count -gt 0) {
    $arguments += "--"
    $arguments += $ScriptArgs
  }

  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $output = & $GodotPath @arguments 2>&1
  $exitCode = $LASTEXITCODE
  $ErrorActionPreference = $previousErrorActionPreference

  return [PSCustomObject]@{
    Code = $exitCode
    Output = $output
    OutputText = ($output | Out-String)
    Arguments = $arguments
    LogResPath = $managedLogResPath
    LogFilesystemPath = $managedLogInvocationPath
    Environment = $environment
  }
}
