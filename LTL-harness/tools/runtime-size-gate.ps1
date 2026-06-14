param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path,
  [string]$ManifestPath = "docs/architectural-gates/runtime-size-gate.md"
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error "RUNTIME_SIZE_GATE_FAIL: $Message"
  exit 1
}

function Resolve-FullPath($Path) {
  return [System.IO.Path]::GetFullPath($Path).TrimEnd("\", "/")
}

function Get-Property($Text, $Key) {
  $escapedKey = [regex]::Escape($Key)
  $pattern = "(?m)^\s*$escapedKey\s*:\s*(.+?)\s*$"
  if ($Text -match $pattern) {
    return $Matches[1].Trim()
  }
  return $null
}

function Parse-CapRules($RawValue, $RuleLabel) {
  $rules = @()
  if ([string]::IsNullOrWhiteSpace($RawValue)) {
    return $rules
  }
  $entries = $RawValue -split ";"
  foreach ($entry in $entries) {
    $trimmed = $entry.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
      continue
    }
    if ($trimmed -notmatch "^(?<pattern>[^=]+?)\s*=\s*(?<limit>\d+)\s*$") {
      Fail "$RuleLabel rule '$trimmed' is invalid; use '<path-or-glob>=<line-cap>' separated by ';'"
    }
    $rules += [PSCustomObject]@{
      Pattern = $Matches["pattern"].Trim().Replace("\", "/")
      Limit = [int]$Matches["limit"]
    }
  }
  return $rules
}

function Get-RelativeToRoot($RootPath, $FullPath) {
  $rootFull = [System.IO.Path]::GetFullPath($RootPath).TrimEnd("\", "/")
  $targetFull = [System.IO.Path]::GetFullPath($FullPath)
  if ($targetFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $targetFull.Substring($rootFull.Length).TrimStart("\", "/").Replace("\", "/")
  }
  return $targetFull.Replace("\", "/")
}

function Convert-GlobToRegex($Pattern) {
  $normalized = $Pattern.Replace("\", "/")
  $escaped = [regex]::Escape($normalized)
  $escaped = $escaped.Replace("\*\*", "__DOUBLE_STAR__")
  $escaped = $escaped.Replace("\*", "[^/]*")
  $escaped = $escaped.Replace("\?", "[^/]")
  $escaped = $escaped.Replace("__DOUBLE_STAR__", ".*")
  return "^$escaped$"
}

function Get-LineCount($FullPath) {
  return (Get-Content -LiteralPath $FullPath).Count
}

$resolvedRoot = Resolve-FullPath $Root
if (-not (Test-Path -LiteralPath $resolvedRoot)) {
  Fail "Root not found: $Root"
}

$resolvedManifest = if ([System.IO.Path]::IsPathRooted($ManifestPath)) {
  $ManifestPath
} else {
  Join-Path $resolvedRoot $ManifestPath
}
if (-not (Test-Path -LiteralPath $resolvedManifest)) {
  Fail "Manifest file not found: $ManifestPath"
}

$manifestText = Get-Content -LiteralPath $resolvedManifest -Raw
$approval = Get-Property $manifestText "approval"
if ($approval -ne "approved") {
  Fail "Manifest approval status is not 'approved' (got '$approval')"
}

$strictPathRules = Parse-CapRules (Get-Property $manifestText "strict_path_caps") "strict_path_caps"
$strictGlobRules = Parse-CapRules (Get-Property $manifestText "strict_glob_caps") "strict_glob_caps"
$legacyDebtPathRules = Parse-CapRules (Get-Property $manifestText "legacy_debt_path_caps") "legacy_debt_path_caps"
if ($strictPathRules.Count -eq 0 -and $strictGlobRules.Count -eq 0 -and $legacyDebtPathRules.Count -eq 0) {
  Fail "Manifest does not declare any strict path, glob, or legacy debt caps"
}

$allFiles = @(Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File | ForEach-Object {
  [PSCustomObject]@{
    FullPath = $_.FullName
    RelativePath = Get-RelativeToRoot $resolvedRoot $_.FullName
  }
})
$lineCountCache = @{}
$exactOverrides = @{}

function Get-CachedLineCount($RelativePath, $FullPath) {
  if (-not $script:lineCountCache.ContainsKey($RelativePath)) {
    $script:lineCountCache[$RelativePath] = Get-LineCount $FullPath
  }
  return [int]$script:lineCountCache[$RelativePath]
}

foreach ($rule in $strictPathRules) {
  $fullPath = Join-Path $resolvedRoot $rule.Pattern
  $fullPath = [System.IO.Path]::GetFullPath($fullPath)
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    Fail "Strict runtime owner path is missing: $($rule.Pattern)"
  }
  $relativePath = Get-RelativeToRoot $resolvedRoot $fullPath
  $lineCount = Get-CachedLineCount $relativePath $fullPath
  if ($lineCount -gt $rule.Limit) {
    Fail "Runtime owner '$relativePath' is $lineCount lines; max allowed is $($rule.Limit)"
  }
  $exactOverrides[$relativePath] = $true
}

foreach ($rule in $legacyDebtPathRules) {
  $fullPath = Join-Path $resolvedRoot $rule.Pattern
  $fullPath = [System.IO.Path]::GetFullPath($fullPath)
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    Fail "Legacy debt runtime owner path is missing: $($rule.Pattern)"
  }
  $relativePath = Get-RelativeToRoot $resolvedRoot $fullPath
  $lineCount = Get-CachedLineCount $relativePath $fullPath
  if ($lineCount -gt $rule.Limit) {
    Fail "Legacy debt runtime owner '$relativePath' is $lineCount lines; frozen max allowed is $($rule.Limit)"
  }
  $exactOverrides[$relativePath] = $true
}

foreach ($rule in $strictGlobRules) {
  $regex = Convert-GlobToRegex $rule.Pattern
  $matchedAny = $false
  foreach ($file in $allFiles) {
    if ($exactOverrides.ContainsKey($file.RelativePath)) {
      continue
    }
    if ($file.RelativePath -notmatch $regex) {
      continue
    }
    $matchedAny = $true
    $lineCount = Get-CachedLineCount $file.RelativePath $file.FullPath
    if ($lineCount -gt $rule.Limit) {
      Fail "Runtime leaf '$($file.RelativePath)' is $lineCount lines; max allowed by '$($rule.Pattern)' is $($rule.Limit)"
    }
  }
  if (-not $matchedAny) {
    Write-Warning "Runtime size glob '$($rule.Pattern)' matched no files"
  }
}

Write-Output "RUNTIME_SIZE_GATE_OK"
