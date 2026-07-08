$ErrorActionPreference = "Stop"

$workspace = "D:\Programming\ex_workspace\LootingTheLeviathan"
$agentRoot = "D:\Programming\ex_workspace\agent-harness"
$backupRoot = Join-Path $workspace "docs\comment-gates\backups\2026-05-21\agent-harness"

New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $agentRoot "docs\templates") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $agentRoot "docs\comment-gates") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $agentRoot "examples\phase-gate-fixtures") -Force | Out-Null

Copy-Item (Join-Path $agentRoot "docs\comment-first-enforcement.md") (Join-Path $backupRoot "comment-first-enforcement.md.bak") -Force
Copy-Item (Join-Path $agentRoot "tools\comment-first-gate.ps1") (Join-Path $backupRoot "comment-first-gate.ps1.bak") -Force
Copy-Item (Join-Path $agentRoot "00_AGENTS.md") (Join-Path $backupRoot "00_AGENTS.md.bak") -Force

$commentFirstDoc = @'
# Comment-First Enforcement

This document is the source of truth for the formal authoring order in the generic agent harness.
The order is strict:

1. `contract-only`
2. `execution-only`
3. `implementation`

Skipping a phase, collapsing phases, or backfilling comments after code is written is a harness violation.

## Core Rule

- Implementation code exists to translate comments, not to invent behavior first.
- A file may move to the next phase only after the current phase is complete, recorded in a ledger, and explicitly approved.
- Passing runtime tests does not excuse a phase-order failure.

## Allowed Content By Phase

### `contract-only`

Allowed:
- `계약:` comments
- blank lines

Forbidden:
- `실행:` comments
- implementation code
- language tokens such as `func`, `class`, `var`, `const`, `return`, `if`, `match`

### `execution-only`

Allowed:
- `계약:` comments
- `실행:` comments
- blank lines

Forbidden:
- implementation code
- new behavior that is not described in the ledger execution scope

### `implementation`

Allowed:
- `계약:` comments
- `실행:` comments
- implementation code

Required:
- every code block must be directly guarded by one `실행:` comment
- `실행 A -> 구현 A -> 실행 B -> 구현 B` ordering only

Forbidden:
- code that appears before an `실행:` comment
- `실행 A -> 실행 B -> 구현 A` ordering
- one `실행:` comment covering multiple unrelated code blocks

## Phase Advancement

### `contract-only -> execution-only`

Requirements:
- ledger exists
- ledger `phase: execution-only`
- ledger `approval: approved`
- target file list matches the files being edited
- target files pass the gate in `execution-only` mode before implementation begins

### `execution-only -> implementation`

Requirements:
- ledger exists
- ledger `phase: implementation-approved`
- ledger `approval: approved`
- target file list matches the files being edited
- target files pass the gate in `execution-only` mode before code is added

## Ledger Requirements

Use `docs/comment-gates/<date>-<task>.md`.

The ledger must include machine-readable fields:

```text
date: YYYY-MM-DD
task: short-task-name
phase: contract-only | execution-only | implementation-approved
approval: approved
targets:
  - relative/path.ext
```

The ledger must also include:
- contract summary
- execution scope
- advancement rule

## Local Backup Policy

Do not rely on remote Git history for harness recovery.

Before editing harness enforcement files, create a local backup set under:

`docs/comment-gates/backups/<yyyy-mm-dd>/<harness-name>/`

Each backup set must include:
- copied source files
- a backup manifest with source path, backup path, timestamp, reason, and restore command

Recovery must be possible with plain filesystem copy commands.

## Hard Stop Conditions

Stop immediately if any of these happen:

- execution comments are added during a `contract-only` request
- implementation code is added during `contract-only` or `execution-only`
- implementation starts without a matching approved ledger
- target files differ from the ledger target list
- code appears without a directly preceding `실행:` comment
- formal implementation is authored in `prototype/**`, `_quarantine*/**`, or `_legacy*/**`

## Violation Handling

1. Move the violating source into `_quarantine_comment_first_violation_<date>/` when the project rule requires quarantine.
2. Remove the violating source from the formal path.
3. Record the violation in worklog or completion notes.
4. Restart from the last valid phase instead of patching comments after the fact.

## Minimum Gate Expectations

The project gate script must be able to verify:

- `contract-only`: contract markers exist, execution markers do not exist, and no code tokens exist
- `execution-only`: contract markers exist, execution markers exist, and no code tokens exist
- `implementation`: contract markers exist, execution markers exist, and every code block is directly guarded by an execution marker
- ledger phase and approval match the requested gate mode
- forbidden directories are rejected
'@
Set-Content -LiteralPath (Join-Path $agentRoot "docs\comment-first-enforcement.md") -Value $commentFirstDoc -Encoding UTF8

$gateScript = @'
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("contract-only", "execution-only", "implementation")]
  [string]$Mode,

  [Parameter(Mandatory = $true)]
  [string]$Root,

  [Parameter(Mandatory = $true)]
  [string[]]$Targets,

  [string]$Ledger
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

function Resolve-InRoot($RootPath, $TargetPath) {
  $resolvedRoot = (Resolve-Path -LiteralPath $RootPath).Path
  $combined = if ([System.IO.Path]::IsPathRooted($TargetPath)) { $TargetPath } else { Join-Path $resolvedRoot $TargetPath }
  $resolvedTarget = (Resolve-Path -LiteralPath $combined).Path
  if (-not $resolvedTarget.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    Fail "target escapes root: $TargetPath"
  }
  return $resolvedTarget
}

function Assert-Not-Forbidden-Path($Path) {
  $normalized = $Path.Replace("/", "\")
  if ($normalized -match "\\prototype\\" -or $normalized -match "\\_quarantine" -or $normalized -match "\\_legacy") {
    Fail "forbidden implementation path: $Path"
  }
}

function Is-CommentOrBlank($Line) {
  $trimmed = $Line.Trim()
  return $trimmed.Length -eq 0 -or
    $trimmed.StartsWith("#") -or
    $trimmed.StartsWith("//") -or
    $trimmed.StartsWith("/*") -or
    $trimmed.StartsWith("*") -or
    $trimmed.StartsWith("*/") -or
    $trimmed.StartsWith("<!--") -or
    $trimmed.StartsWith("-->")
}

function Looks-Like-Code($Line) {
  $trimmed = $Line.Trim()
  if ($trimmed.Length -eq 0) { return $false }
  if (Is-CommentOrBlank $Line) { return $false }
  return $true
}

function Has-ContractMarker($Text) {
  return $Text.Contains("계약:")
}

function Has-ExecutionMarker($Text) {
  return $Text.Contains("실행:")
}

function Test-NoCodeTokens($Path) {
  $lines = Get-Content -LiteralPath $Path
  for ($index = 0; $index -lt $lines.Count; $index++) {
    if (Looks-Like-Code $lines[$index]) {
      Fail "$Mode gate failed: $Path line $($index + 1) contains implementation code"
    }
  }
}

function Previous-MeaningfulLine($Lines, $Index) {
  for ($cursor = $Index - 1; $cursor -ge 0; $cursor--) {
    if ($Lines[$cursor].Trim().Length -gt 0) {
      return $Lines[$cursor].Trim()
    }
  }
  return ""
}

function Assert-ContractOnly($Path) {
  Assert-Not-Forbidden-Path $Path
  $text = Get-Content -LiteralPath $Path -Raw
  if (-not (Has-ContractMarker $text)) {
    Fail "contract-only gate failed: missing contract marker in $Path"
  }
  if (Has-ExecutionMarker $text) {
    Fail "contract-only gate failed: execution comments were added before an execution-comment request in $Path"
  }
  Test-NoCodeTokens $Path
}

function Assert-ExecutionOnly($Path) {
  Assert-Not-Forbidden-Path $Path
  $text = Get-Content -LiteralPath $Path -Raw
  if (-not (Has-ContractMarker $text)) {
    Fail "execution-only gate failed: missing contract marker in $Path"
  }
  if (-not (Has-ExecutionMarker $text)) {
    Fail "execution-only gate failed: missing execution marker in $Path"
  }
  Test-NoCodeTokens $Path
}

function Assert-Implementation($Path) {
  Assert-Not-Forbidden-Path $Path
  $text = Get-Content -LiteralPath $Path -Raw
  if (-not (Has-ContractMarker $text)) {
    Fail "implementation gate failed: missing contract marker in $Path"
  }
  if (-not (Has-ExecutionMarker $text)) {
    Fail "implementation gate failed: missing execution marker in $Path"
  }

  $lines = Get-Content -LiteralPath $Path
  for ($index = 0; $index -lt $lines.Count; $index++) {
    if (Looks-Like-Code $lines[$index]) {
      $previous = Previous-MeaningfulLine $lines $index
      if (-not $previous.Contains("실행:")) {
        Fail "implementation gate failed: code line $($index + 1) is not directly guarded by an execution comment in $Path"
      }
    }
  }
}

function Assert-LedgerPhase($LedgerText, $ExpectedPhase, $LedgerPath) {
  if (-not $LedgerText.Contains("phase: $ExpectedPhase")) {
    Fail "ledger phase mismatch in ${LedgerPath}: expected $ExpectedPhase"
  }
}

function Assert-LedgerApproval($LedgerText, $LedgerPath) {
  if (-not $LedgerText.Contains("approval: approved")) {
    Fail "ledger approval missing in $LedgerPath"
  }
}

function Assert-LedgerTargets($LedgerText, $TargetsToCheck, $LedgerPath) {
  foreach ($target in $TargetsToCheck) {
    if (-not $LedgerText.Contains("- $target")) {
      Fail "ledger target mismatch in ${LedgerPath}: missing $target"
    }
  }
}

if ($Mode -eq "execution-only" -or $Mode -eq "implementation") {
  if ([string]::IsNullOrWhiteSpace($Ledger)) {
    Fail "$Mode gate requires -Ledger"
  }
  $ledgerPath = Resolve-InRoot $Root $Ledger
  $ledgerText = Get-Content -LiteralPath $ledgerPath -Raw
  Assert-LedgerApproval $ledgerText $Ledger
  Assert-LedgerTargets $ledgerText $Targets $Ledger
  if ($Mode -eq "execution-only") {
    Assert-LedgerPhase $ledgerText "execution-only" $Ledger
  }
  if ($Mode -eq "implementation") {
    Assert-LedgerPhase $ledgerText "implementation-approved" $Ledger
  }
}

foreach ($target in $Targets) {
  $path = Resolve-InRoot $Root $target
  switch ($Mode) {
    "contract-only" { Assert-ContractOnly $path }
    "execution-only" { Assert-ExecutionOnly $path }
    "implementation" { Assert-Implementation $path }
  }
}

Write-Output "COMMENT_FIRST_GATE_OK"
'@
Set-Content -LiteralPath (Join-Path $agentRoot "tools\comment-first-gate.ps1") -Value $gateScript -Encoding UTF8

$ledgerTemplate = @'
# Comment Gate Ledger

date: YYYY-MM-DD
task: short-task-name
phase: contract-only
approval: approved
targets:
  - relative/path.ext

## Contract Summary

- Summarize the rule or contract that is fixed in this phase.

## Execution Scope

- List the execution comments or implementation blocks that this ledger is allowed to cover.

## Advancement Rule

- next_phase: execution-only
- required_user_request: explicit
'@
Set-Content -LiteralPath (Join-Path $agentRoot "docs\templates\comment-gate-ledger-template.md") -Value $ledgerTemplate -Encoding UTF8

$backupTemplate = @'
# Backup Manifest

date: YYYY-MM-DD
harness: agent-harness
reason: short-reason

## Files

- source: path/to/source
  backup: path/to/backup
  restore: Copy-Item -LiteralPath <backup> -Destination <source> -Force
'@
Set-Content -LiteralPath (Join-Path $agentRoot "docs\templates\backup-manifest-template.md") -Value $backupTemplate -Encoding UTF8

$examplesDoc = @'
# Phase Gate Examples

## Valid: contract-only

- File contains `# 계약:` comments only.
- File contains no `# 실행:` lines.
- File contains no code tokens.

## Invalid: contract-only

- File contains any `# 실행:` line.
- File contains any implementation token such as `func`, `class`, `var`, `const`, `return`, `if`, `match`.

## Valid: execution-only

- File contains `# 계약:` and `# 실행:` comments.
- File contains no code tokens.

## Invalid: execution-only

- File contains implementation code.
- File contains `# 실행:` lines that are not covered by the ledger phase.

## Valid: implementation

- File contains `# 계약:` comments.
- File contains `# 실행:` comments immediately above each code block.
- Ledger phase is `implementation-approved`.

## Regression: contract request accidentally includes execution comments

- Request: `계약 주석 작성`
- File state: contains `계약:` and `실행:`
- Expected: `contract-only` gate fails before implementation starts
'@
Set-Content -LiteralPath (Join-Path $agentRoot "docs\phase-gate-examples.md") -Value $examplesDoc -Encoding UTF8

$exampleLedger = @'
# Comment Gate Ledger

date: YYYY-MM-DD
task: generic-phase-gate-example
phase: execution-only
approval: approved
targets:
  - examples/phase-gate-fixtures/execution-only.txt

## Contract Summary

- generic fixture for validating phase-aware comment gate behavior

## Execution Scope

- execution-only fixture for the generic harness gate

## Advancement Rule

- next_phase: implementation
- required_user_request: explicit
'@
Set-Content -LiteralPath (Join-Path $agentRoot "docs\comment-gates\example-phase-ledger.md") -Value $exampleLedger -Encoding UTF8

$contractFixture = @'
# 계약:
# - purpose: generic contract-only fixture for comment gate verification
# - allowed: contract comments only
'@
Set-Content -LiteralPath (Join-Path $agentRoot "examples\phase-gate-fixtures\contract-only.txt") -Value $contractFixture -Encoding UTF8

$executionFixture = @'
# 계약:
# - purpose: generic execution-only fixture for comment gate verification
# 실행:
# - purpose: generic execution comment fixture for phase advancement checks
'@
Set-Content -LiteralPath (Join-Path $agentRoot "examples\phase-gate-fixtures\execution-only.txt") -Value $executionFixture -Encoding UTF8

$implementationFixture = @'
# 계약:
# - purpose: generic implementation fixture for comment gate verification
# 실행:
print("generic fixture")
'@
Set-Content -LiteralPath (Join-Path $agentRoot "examples\phase-gate-fixtures\implementation.txt") -Value $implementationFixture -Encoding UTF8

$agentsPath = Join-Path $agentRoot "00_AGENTS.md"
$lines = Get-Content -LiteralPath $agentsPath
$insertAt = 49
$block = @(
  '### Three-Phase Comment Gate',
  '- Comment-first SoT is `docs/comment-first-enforcement.md`.',
  '- Formal source work must advance in this exact order: `contract-only -> execution-only -> implementation`.',
  '- `contract-only` allows only `계약:` comments.',
  '- `execution-only` allows `계약:` comments and `실행:` comments, but no implementation code.',
  '- `implementation` requires an approved ledger with `phase: implementation-approved`.',
  '- Every implementation block must be directly guarded by one `실행:` comment.',
  '- Before editing harness enforcement files, create a local backup set under `docs/comment-gates/backups/<date>/agent-harness/`.',
  '- If phase order is violated, quarantine or roll back from the last valid phase instead of backfilling comments after code.',
  ''
)
$updated = @()
$updated += $lines[0..($insertAt-1)]
$updated += $block
$updated += $lines[$insertAt..($lines.Count-1)]
Set-Content -LiteralPath $agentsPath -Value $updated -Encoding UTF8

$backupManifest = @'
# Backup Manifest

date: 2026-05-21
harness: agent-harness
reason: three-phase comment gate redesign

## Files

- source: D:/Programming/ex_workspace/agent-harness/docs/comment-first-enforcement.md
  backup: docs/comment-gates/backups/2026-05-21/agent-harness/comment-first-enforcement.md.bak
  restore: Copy-Item -LiteralPath "docs/comment-gates/backups/2026-05-21/agent-harness/comment-first-enforcement.md.bak" -Destination "D:/Programming/ex_workspace/agent-harness/docs/comment-first-enforcement.md" -Force

- source: D:/Programming/ex_workspace/agent-harness/tools/comment-first-gate.ps1
  backup: docs/comment-gates/backups/2026-05-21/agent-harness/comment-first-gate.ps1.bak
  restore: Copy-Item -LiteralPath "docs/comment-gates/backups/2026-05-21/agent-harness/comment-first-gate.ps1.bak" -Destination "D:/Programming/ex_workspace/agent-harness/tools/comment-first-gate.ps1" -Force

- source: D:/Programming/ex_workspace/agent-harness/00_AGENTS.md
  backup: docs/comment-gates/backups/2026-05-21/agent-harness/00_AGENTS.md.bak
  restore: Copy-Item -LiteralPath "docs/comment-gates/backups/2026-05-21/agent-harness/00_AGENTS.md.bak" -Destination "D:/Programming/ex_workspace/agent-harness/00_AGENTS.md" -Force
'@
Set-Content -LiteralPath (Join-Path $backupRoot "backup-manifest.md") -Value $backupManifest -Encoding UTF8

Get-ChildItem $backupRoot | Select-Object Name,Length
