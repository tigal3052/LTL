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

function Normalize-RepoPath($Path) {
  return ([string]$Path).Trim().Replace("\", "/")
}

function Convert-GlobToRegex($Pattern) {
  $normalized = (Normalize-RepoPath $Pattern)
  $escaped = [regex]::Escape($normalized)
  $escaped = $escaped.Replace("\*\*", "__DOUBLE_STAR__")
  $escaped = $escaped.Replace("\*", "[^/]*")
  $escaped = $escaped.Replace("\?", "[^/]")
  $escaped = $escaped.Replace("__DOUBLE_STAR__", ".*")
  return "^$escaped$"
}

function Get-CapRules($ManifestText, $Field) {
  $rules = New-Object System.Collections.Generic.List[object]
  $match = [System.Text.RegularExpressions.Regex]::Match($ManifestText, ('(?m)^\s*{0}\s*:\s*(.+)\s*$' -f [regex]::Escape($Field)))
  if (-not $match.Success) {
    return $rules
  }
  foreach ($entry in ($match.Groups[1].Value -split ';')) {
    $trimmed = $entry.Trim()
    if ($trimmed -match "^(?<pattern>[^=]+?)\s*=\s*(?<limit>\d+)\s*$") {
      $rules.Add([PSCustomObject]@{
        Pattern = Normalize-RepoPath $Matches["pattern"]
        Limit = [int]$Matches["limit"]
      })
    }
  }
  return $rules
}

function Get-CandidateLineCount($RepoRoot, $RelativePath) {
  $fullPath = Join-Path $RepoRoot (Normalize-RepoPath $RelativePath)
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    return 0
  }
  return (Get-Content -LiteralPath $fullPath).Count
}

function Get-RuntimeSizeMonitoredPaths($RepoRoot, [string[]]$CandidatePaths = @()) {
  $manifestPath = Join-Path $RepoRoot "docs/architectural-gates/runtime-size-gate.md"
  if (-not (Test-Path -LiteralPath $manifestPath)) {
    return @()
  }
  $manifestText = Get-Content -LiteralPath $manifestPath -Raw
  $paths = New-Object System.Collections.Generic.List[string]
  foreach ($field in @('legacy_debt_path_caps', 'strict_path_caps')) {
    foreach ($pathRule in (Get-CapRules $manifestText $field)) {
      $paths.Add($pathRule.Pattern)
    }
  }
  $normalizedCandidates = @($CandidatePaths | ForEach-Object { Normalize-RepoPath $_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
  if ($normalizedCandidates.Count -gt 0) {
    foreach ($globRule in (Get-CapRules $manifestText 'strict_glob_caps')) {
      $regex = Convert-GlobToRegex $globRule.Pattern
      $softLimit = [int][Math]::Floor($globRule.Limit * 0.8)
      foreach ($candidatePath in $normalizedCandidates) {
        if ($candidatePath -match $regex) {
          $lineCount = Get-CandidateLineCount $RepoRoot $candidatePath
          if ($lineCount -ge $softLimit) {
            $paths.Add($candidatePath)
          }
        }
      }
    }
  }
  return @($paths | Select-Object -Unique)
}

function Get-HighFrequencyRuntimePaths() {
  return @(
    "app-LTL/src/MainControllerRuntime.gd",
    "app-LTL/src/ui/MainViewRuntime.gd",
    "app-LTL/src/ui/BattlefieldUI.gd",
    "app-LTL/src/ui/BattlefieldVFX.gd",
    "app-LTL/src/ui/VFXManager.gd",
    "app-LTL/src/phases/CombatPhase.gd",
    "app-LTL/src/vocabulary/CombatVocab.gd"
  )
}

function Get-FeatureUnitLifecycleScopePaths($Sections) {
  $mutableScopePaths = @(Get-BacktickedPaths ([string]$Sections["mutable scope"]) | ForEach-Object { Normalize-RepoPath $_ } | Select-Object -Unique)
  if ($mutableScopePaths.Count -eq 0) {
    return @()
  }
  return @($mutableScopePaths | Where-Object {
    $_ -match '^app-LTL/src/' -or
    $_ -match '^LTL-harness/' -or
    $_ -match '^docs/architectural-gates/' -or
    $_ -eq 'docs/source-map.md'
  } | Select-Object -Unique)
}

function Require-FeatureUnitLifecyclePlan($Sections) {
  $lifecycleScopePaths = @(Get-FeatureUnitLifecycleScopePaths $Sections)
  if ($lifecycleScopePaths.Count -eq 0) {
    return
  }
  Require-MeaningfulSection $Sections "Feature Unit Lifecycle Plan" "map source or harness scope to design, implementation, and maintenance-stage feature-unit boundaries before editing"
  $body = [string]$Sections["feature unit lifecycle plan"]
  Require-SectionLine $body '(?m)^\s*-\s*Design stage:\s+.+$' "Feature Unit Lifecycle Plan must declare the Design stage boundary"
  Require-SectionLine $body '(?m)^\s*-\s*Implementation stage:\s+.+$' "Feature Unit Lifecycle Plan must declare the Implementation stage split rule"
  Require-SectionLine $body '(?m)^\s*-\s*Maintenance stage:\s+.+$' "Feature Unit Lifecycle Plan must declare the Maintenance stage drift guard"
  Require-SectionLine $body '(?m)^\s*-\s*Capsule boundary:\s+.+$' "Feature Unit Lifecycle Plan must declare the Capsule boundary"
  Require-SectionLine $body '(?m)^\s*-\s*Size trigger:\s+.+$' "Feature Unit Lifecycle Plan must declare the Size trigger"
}

function Require-RuntimePerformanceCoverage($Sections) {
  $mutableScopePaths = @(Get-BacktickedPaths ([string]$Sections["mutable scope"]) | ForEach-Object { Normalize-RepoPath $_ } | Select-Object -Unique)
  if ($mutableScopePaths.Count -eq 0) {
    return
  }
  $hotPaths = @(Get-HighFrequencyRuntimePaths)
  $hotInScope = @($mutableScopePaths | Where-Object { $hotPaths -contains $_ } | Select-Object -Unique)
  if ($hotInScope.Count -eq 0) {
    return
  }
  Require-MeaningfulSection $Sections "Runtime Performance Review" "map each touched high-frequency runtime path to a hot path, risk, performance proof, and budget before editing"
  $body = [string]$Sections["runtime performance review"]
  Require-SectionLine $body '(?m)^\s*-\s*Hot path:\s*`[^`]+`\s+.+$' "Runtime Performance Review must declare a Hot path with a concrete owner/function"
  Require-SectionLine $body '(?m)^\s*-\s*Risk:\s+.+$' "Runtime Performance Review must declare the performance Risk"
  Require-SectionLine $body '(?m)^\s*-\s*Performance proof:\s*`[^`]+`\s*$' "Runtime Performance Review must declare a Performance proof path"
  Require-SectionLine $body '(?m)^\s*-\s*Budget:\s+.+$' "Runtime Performance Review must declare a measurable Budget"
  foreach ($hotPath in $hotInScope) {
    if ($body -notmatch [regex]::Escape($hotPath)) {
      Fail "Runtime Performance Review must name touched high-frequency runtime path: $hotPath"
    }
  }
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
  $mutableScopePaths = @(Get-BacktickedPaths ([string]$Sections["mutable scope"]) | ForEach-Object { Normalize-RepoPath $_ } | Select-Object -Unique)
  if ($mutableScopePaths.Count -eq 0) {
    return
  }
  $monitoredOwnerPaths = @(Get-RuntimeSizeMonitoredPaths $RepoRoot $mutableScopePaths)
  if ($monitoredOwnerPaths.Count -eq 0) {
    return
  }
  $monitoredInScope = @($mutableScopePaths | Where-Object { $monitoredOwnerPaths -contains $_ } | Select-Object -Unique)
  if ($monitoredInScope.Count -eq 0) {
    return
  }
  if (-not $Sections.ContainsKey("execution responsibility units")) {
    Fail "Execution Responsibility Units section is required for monitored runtime paths: $($monitoredInScope -join ', ')"
  }
  Require-MeaningfulSection $Sections "Execution Responsibility Units" "map each touched large runtime owner to a split unit, extraction target, and focused proof before editing"
  $blocks = @(Get-ExecutionResponsibilityUnitBlocks ([string]$Sections["execution responsibility units"]))
  foreach ($ownerPath in $monitoredInScope) {
    $block = $blocks | Where-Object { (Normalize-RepoPath $_.Owner) -eq $ownerPath } | Select-Object -First 1
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
Require-FeatureUnitLifecyclePlan $sections
Require-RuntimePerformanceCoverage $sections

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
