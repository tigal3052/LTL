param(
  [Parameter(Mandatory = $false)]
  [string]$Root
)

if ([string]::IsNullOrWhiteSpace($Root)) {
  $Root = (Resolve-Path ".").Path
}

$ErrorActionPreference = "Stop"
$resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
$catalogPath = Join-Path $resolvedRoot "app-LTL/src/ui/TextCatalog.gd"

function Fail($Message) {
  Write-Error "I18N_TEXT_GATE_FAIL: $Message"
  exit 1
}

if (-not (Test-Path -LiteralPath $catalogPath)) {
  Fail "missing TextCatalog.gd at app-LTL/src/ui/TextCatalog.gd"
}

$scanRoots = @(
  "app-LTL/src/ui",
  "app-LTL/src/scenes"
)

$forbidden = @(
  "Start Combat",
  "Claim Rewards",
  "Reset Run",
  "Hold Fire",
  "DISCARD ZONE",
  "No pending rewards",
  "Beacon Effects",
  "Cooldown:",
  "Damage:",
  "Phase:",
  "Stage "
)

foreach ($scanRoot in $scanRoots) {
  $fullRoot = Join-Path $resolvedRoot $scanRoot
  if (-not (Test-Path -LiteralPath $fullRoot)) {
    continue
  }
  $files = Get-ChildItem -LiteralPath $fullRoot -Recurse -File | Where-Object {
    $_.Extension -in @(".gd", ".tscn")
  }
  foreach ($file in $files) {
    if ($file.FullName -eq $catalogPath) {
      continue
    }
    $text = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($needle in $forbidden) {
      if ($text.Contains($needle)) {
        $relative = $file.FullName.Substring($resolvedRoot.Length).TrimStart("\", "/")
        Fail "hardcoded user-facing English text '$needle' found in $relative; route it through TextCatalog"
      }
    }
  }
}

Write-Output "I18N_TEXT_GATE_OK"
exit 0
