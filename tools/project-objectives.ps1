param(
  [Parameter(Mandatory = $false)]
  [ValidateSet("inspect", "validate", "list", "new-template", "add-objective", "update-status")]
  [string]$Mode = "inspect",

  [Parameter(Mandatory = $false)]
  [string]$ObjectiveId = "",

  [Parameter(Mandatory = $false)]
  [ValidateSet("high", "medium", "low")]
  [string]$Priority = "medium",

  [Parameter(Mandatory = $false)]
  [ValidateSet("pending", "in-progress", "completed", "blocked", "deferred", "cancelled")]
  [string]$Status = "pending",

  [Parameter(Mandatory = $false)]
  [string]$Area = "General",

  [Parameter(Mandatory = $false)]
  [string]$Title = "",

  [Parameter(Mandatory = $false)]
  [string]$Description = "",

  [Parameter(Mandatory = $false)]
  [string]$Note = "",

  [Parameter(Mandatory = $false)]
  [switch]$DryRun,

  [Parameter(Mandatory = $false)]
  [string]$Root = (Resolve-Path ".").Path,

  [Parameter(Mandatory = $false)]
  [string]$GenericHarnessRoot = ""
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error "LTL_PROJECT_OBJECTIVES_FAIL: $Message"
  exit 1
}

$resolvedRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd("\", "/")
if ([string]::IsNullOrWhiteSpace($GenericHarnessRoot)) {
  $GenericHarnessRoot = Join-Path $resolvedRoot "..\agent-harness"
}
$genericGate = Join-Path $GenericHarnessRoot "tools\project-objective-gate.ps1"
if (-not (Test-Path -LiteralPath $genericGate)) {
  Fail "Generic project-objective gate not found: $genericGate"
}

$args = @(
  "-NoProfile", "-ExecutionPolicy", "Bypass",
  "-File", $genericGate,
  "-Root", $resolvedRoot,
  "-ConfigPath", ".agent-harness.json",
  "-Mode", $Mode
)

if (-not [string]::IsNullOrWhiteSpace($ObjectiveId)) { $args += @("-ObjectiveId", $ObjectiveId) }
if ($PSBoundParameters.ContainsKey("Priority")) { $args += @("-Priority", $Priority) }
if ($PSBoundParameters.ContainsKey("Status")) { $args += @("-Status", $Status) }
if (-not [string]::IsNullOrWhiteSpace($Area)) { $args += @("-Area", $Area) }
if (-not [string]::IsNullOrWhiteSpace($Title)) { $args += @("-Title", $Title) }
if (-not [string]::IsNullOrWhiteSpace($Description)) { $args += @("-Description", $Description) }
if (-not [string]::IsNullOrWhiteSpace($Note)) { $args += @("-Note", $Note) }
if ($DryRun) {
  $args += "-DryRun"
}

& powershell @args
exit $LASTEXITCODE
