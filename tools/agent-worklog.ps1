param(
  [Parameter(Mandatory = $false)]
  [ValidateSet("inspect", "preflight", "validate", "summarize-worklogs", "token-report", "compact-log", "new-log")]
  [string]$Mode = "inspect",

  [Parameter(Mandatory = $false)]
  [string]$Task = "",

  [Parameter(Mandatory = $false)]
  [string]$Agent = "hermes",

  [Parameter(Mandatory = $false)]
  [switch]$DryRun,

  [Parameter(Mandatory = $false)]
  [int]$RecentLimit = 16,

  [Parameter(Mandatory = $false)]
  [string]$Root = (Resolve-Path ".").Path,

  [Parameter(Mandatory = $false)]
  [string]$GenericHarnessRoot = ""
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error "LTL_AGENT_WORKLOG_FAIL: $Message"
  exit 1
}

$resolvedRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd("\", "/")
if ([string]::IsNullOrWhiteSpace($GenericHarnessRoot)) {
  $GenericHarnessRoot = Join-Path $resolvedRoot "..\agent-harness"
}
$genericGate = Join-Path $GenericHarnessRoot "tools\worklog-token-gate.ps1"
if (-not (Test-Path -LiteralPath $genericGate)) {
  Fail "Generic worklog-token gate not found: $genericGate"
}

$args = @(
  "-NoProfile", "-ExecutionPolicy", "Bypass",
  "-File", $genericGate,
  "-Root", $resolvedRoot,
  "-ConfigPath", ".agent-harness.json",
  "-Mode", $Mode,
  "-RecentLimit", $RecentLimit
)
if (-not [string]::IsNullOrWhiteSpace($Task)) {
  $args += @("-Task", $Task)
}
if (-not [string]::IsNullOrWhiteSpace($Agent)) {
  $args += @("-Agent", $Agent)
}
if ($DryRun) {
  $args += "-DryRun"
}

& powershell @args
exit $LASTEXITCODE
