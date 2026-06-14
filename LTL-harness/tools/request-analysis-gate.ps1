param(
  [Parameter(Mandatory = $false)]
  [string]$Ledger,

  [Parameter(Mandatory = $false)]
  [ValidateSet("pre-edit", "pre-complete")]
  [string]$Mode = "pre-edit",

  [Parameter(Mandatory = $false)]
  [switch]$RequireArtifactLedger
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error "REQUEST_ANALYSIS_GATE_FAIL: $Message"
  exit 1
}

function Resolve-FullPath($Path) {
  return [System.IO.Path]::GetFullPath($Path)
}

function Get-SectionBodies($Text) {
  $sections = @{}
  $currentName = $null
  $buffer = New-Object System.Collections.Generic.List[string]
  foreach ($line in ($Text -split "`r?`n")) {
    if ($line -match "^\s*#{2,6}\s+(.+?)\s*$") {
      if ($null -ne $currentName) {
        $sections[$currentName] = ($buffer -join [Environment]::NewLine).Trim()
      }
      $currentName = $Matches[1].Trim().ToLowerInvariant()
      $buffer = New-Object System.Collections.Generic.List[string]
      continue
    }
    if ($null -ne $currentName) {
      $buffer.Add($line)
    }
  }
  if ($null -ne $currentName) {
    $sections[$currentName] = ($buffer -join [Environment]::NewLine).Trim()
  }
  return $sections
}

function Require-Section($Sections, $Name) {
  if (-not $Sections.ContainsKey($Name.ToLowerInvariant())) {
    Fail "Ledger is missing required section: $Name"
  }
}

function Require-MeaningfulSection($Sections, $Name, $Expectation) {
  Require-Section $Sections $Name
  $body = [string]$Sections[$Name.ToLowerInvariant()]
  if ([string]::IsNullOrWhiteSpace($body)) {
    Fail "$Name section is empty; $Expectation"
  }
  if ($body -match "(?i)\b(TODO|TBD|PLACEHOLDER)\b") {
    Fail "$Name section still uses placeholder text; $Expectation"
  }
}

function Require-SectionLine($Body, $Pattern, $FailureMessage) {
  if ([string]::IsNullOrWhiteSpace($Body) -or $Body -notmatch $Pattern) {
    Fail $FailureMessage
  }
}

function Get-BacktickedPaths($Text) {
  $paths = New-Object System.Collections.Generic.List[string]
  if ([string]::IsNullOrWhiteSpace($Text)) {
    return $paths
  }
  foreach ($match in [System.Text.RegularExpressions.Regex]::Matches($Text, '`([^`]+)`')) {
    $candidate = $match.Groups[1].Value.Trim()
    if (-not [string]::IsNullOrWhiteSpace($candidate)) {
      $paths.Add($candidate)
    }
  }
  return $paths
}

function Get-RuntimeSizeMonitoredPaths($RepoRoot) {
  $manifestPath = Join-Path $RepoRoot "docs/architectural-gates/runtime-size-gate.md"
  if (-not (Test-Path -LiteralPath $manifestPath)) {
    return @()
  }
  $manifestText = Get-Content -LiteralPath $manifestPath -Raw
  $paths = New-Object System.Collections.Generic.List[string]
  foreach ($field in @('legacy_debt_path_caps', 'strict_path_caps')) {
    $match = [System.Text.RegularExpressions.Regex]::Match($manifestText, ('(?m)^\s*{0}\s*:\s*(.+)\s*$' -f [regex]::Escape($field)))
    if (-not $match.Success) {
      continue
    }
    foreach ($entry in ($match.Groups[1].Value -split ';')) {
      $candidate = (($entry -split '=')[0]).Trim()
      if (-not [string]::IsNullOrWhiteSpace($candidate)) {
        $paths.Add($candidate)
      }
    }
  }
  return @($paths | Select-Object -Unique)
}

function Get-ExecutionResponsibilityUnitBlocks($Body) {
  $blocks = @()
  $current = $null
  $buffer = New-Object System.Collections.Generic.List[string]
  foreach ($line in ($Body -split "`r?`n")) {
    if ($line -match '^\s*-\s*Owner:\s*`([^`]+)`\s*$') {
      if ($null -ne $current) {
        $blocks += [PSCustomObject]@{
          Owner = $current
          Body = ($buffer -join [Environment]::NewLine).Trim()
        }
      }
      $current = $Matches[1].Trim()
      $buffer = New-Object System.Collections.Generic.List[string]
      continue
    }
    if ($null -ne $current) {
      $buffer.Add($line)
    }
  }
  if ($null -ne $current) {
    $blocks += [PSCustomObject]@{
      Owner = $current
      Body = ($buffer -join [Environment]::NewLine).Trim()
    }
  }
  return $blocks
}

function Require-ExecutionResponsibilityCoverage($Sections, $RepoRoot) {
  $mutableScopePaths = @(Get-BacktickedPaths ([string]$Sections["mutable scope"]))
  if ($mutableScopePaths.Count -eq 0) {
    return
  }
  $monitoredOwnerPaths = @(Get-RuntimeSizeMonitoredPaths $RepoRoot)
  if ($monitoredOwnerPaths.Count -eq 0) {
    return
  }
  $monitoredInScope = @($mutableScopePaths | Where-Object { $monitoredOwnerPaths -contains $_ } | Select-Object -Unique)
  if ($monitoredInScope.Count -eq 0) {
    return
  }
  Require-MeaningfulSection $Sections "Execution Responsibility Units" "map each touched large runtime owner to a split unit, extraction target, and focused proof before editing"
  $blocks = @(Get-ExecutionResponsibilityUnitBlocks ([string]$Sections["execution responsibility units"]))
  foreach ($ownerPath in $monitoredInScope) {
    $block = $blocks | Where-Object { $_.Owner -eq $ownerPath } | Select-Object -First 1
    if ($null -eq $block) {
      Fail "Execution Responsibility Units must include Owner coverage for monitored runtime path: $ownerPath"
    }
    if ($block.Body -match '(?i)\b(TODO|TBD|PLACEHOLDER)\b') {
      Fail "Execution Responsibility Units for $ownerPath still contains placeholder text"
    }
    if ($block.Body -notmatch '(?m)^\s*-\s*Unit:\s+.+$') {
      Fail "Execution Responsibility Units for $ownerPath must declare a concrete Unit"
    }
    if ($block.Body -notmatch '(?m)^\s*-\s*Extract to:\s*`[^`]+`\s*$') {
      Fail "Execution Responsibility Units for $ownerPath must declare an Extract to helper path"
    }
    if ($block.Body -notmatch '(?m)^\s*-\s*Focused proof:\s*`[^`]+`\s*$') {
      Fail "Execution Responsibility Units for $ownerPath must declare a Focused proof path"
    }
  }
}

function Require-RootCauseReview($Sections) {
  Require-MeaningfulSection $Sections "Root Cause Review" "capture the symptom, evidence, source-level target, rejected workaround, and chosen fix before editing"
  $body = [string]$Sections["root cause review"]
  Require-SectionLine $body '(?m)^\s*-\s*Observed symptom:\s+.+$' "Root Cause Review must declare an Observed symptom"
  Require-SectionLine $body '(?m)^\s*-\s*Evidence:\s+.+$' "Root Cause Review must declare concrete Evidence"
  Require-SectionLine $body '(?m)^\s*-\s*Root cause target:\s*(?:`[^`]+`|[A-Za-z0-9_./\\:-]+)\s*$' "Root Cause Review must declare a Root cause target path or owner"
  Require-SectionLine $body '(?m)^\s*-\s*Rejected workaround:\s+.+$' "Root Cause Review must declare the Rejected workaround that is being avoided"
  Require-SectionLine $body '(?m)^\s*-\s*Chosen fix:\s+.+$' "Root Cause Review must declare the Chosen fix"
}

function Require-ResolutionProof($Sections) {
  Require-MeaningfulSection $Sections "Resolution Proof" "map failing proof, root-cause proof, and workaround-guard evidence before completion"
  $body = [string]$Sections["resolution proof"]
  if ($body -match '(?i)\bpending\b') {
    Fail "Resolution Proof cannot stay pending at pre-complete time"
  }
  Require-SectionLine $body '(?m)^\s*-\s*RED proof:\s+.+$' "Resolution Proof must declare a RED proof"
  Require-SectionLine $body '(?m)^\s*-\s*Root-cause proof:\s+.+$' "Resolution Proof must declare a Root-cause proof"
  Require-SectionLine $body '(?m)^\s*-\s*Workaround guard:\s+.+$' "Resolution Proof must declare a Workaround guard result"
}

if ([string]::IsNullOrWhiteSpace($Ledger)) {
  Fail "Ledger is required. Usage: request-analysis-gate.ps1 -Ledger <ledger.md> [-Mode pre-edit|pre-complete] [-RequireArtifactLedger]"
}

$ledgerPath = Resolve-FullPath $Ledger
$repoRoot = Resolve-FullPath (Join-Path $PSScriptRoot "../..")
if (-not (Test-Path -LiteralPath $ledgerPath)) {
  Fail "Ledger file not found: $Ledger"
}

$ledgerText = Get-Content -LiteralPath $ledgerPath -Raw
$sections = Get-SectionBodies $ledgerText

Require-Section $sections "Request Summary"
Require-Section $sections "Preserved Invariants"
Require-Section $sections "Mutable Scope"
Require-MeaningfulSection $sections "Source Map Findings" "record the source-map-derived files, paths, or observations that scoped this request"
Require-RootCauseReview $sections
Require-MeaningfulSection $sections "Transition Safety Review" "declare touched transitions or explicit no-transition-impact coverage"
Require-Section $sections "Refactor/Delete Disposition"
Require-Section $sections "Verification Checklist"
if (-not ([string]$sections["source map findings"] -match '`[^`]+`|source-map')) {
  Fail "Source Map Findings must cite at least one mapped path or explicit source-map observation"
}

if ($Mode -eq "pre-complete") {
  Require-Section $sections "Verification Notes"
  Require-ResolutionProof $sections
}
else {
  Require-ExecutionResponsibilityCoverage $sections $repoRoot
}

if ($RequireArtifactLedger) {
  Require-Section $sections "Artifact Ledger"
}

Write-Output "REQUEST_ANALYSIS_GATE_OK"
exit 0
