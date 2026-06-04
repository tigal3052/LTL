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
$rewardTablePath = Join-Path $resolvedRoot "app-LTL/src/data/reward-table.json"

function Fail($Message) {
  Write-Error "I18N_TEXT_GATE_FAIL: $Message"
  exit 1
}

function Read-Utf8Text([string]$Path) {
  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Get-Prop($Object, [string]$Name) {
  if ($null -eq $Object) {
    return $null
  }
  $prop = $Object.PSObject.Properties[$Name]
  if ($null -eq $prop) {
    return $null
  }
  return $prop.Value
}

function Has-NonEmptyLocalizedValue($Object, [string]$Name) {
  $value = Get-Prop $Object $Name
  return $null -ne $value -and -not [string]::IsNullOrWhiteSpace([string]$value)
}

function Assert-LocalizedPair($Object, [string]$Path) {
  if (-not (Has-NonEmptyLocalizedValue $Object "ko") -or -not (Has-NonEmptyLocalizedValue $Object "en")) {
    Fail "$Path must define non-empty ko/en localized text"
  }
}

function Test-ReadableKoreanValue([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $false
  }
  if ($Value.Contains("?") -or $Value.Contains([string][char]0xFFFD)) {
    return $false
  }
  return [regex]::IsMatch($Value, "[\uAC00-\uD7A3\u3131-\u318E]")
}

function Assert-ReadableKoreanValue([string]$Value, [string]$Path) {
  if (-not (Test-ReadableKoreanValue $Value)) {
    Fail "$Path must contain readable Korean text; placeholder question marks or encoding-loss text are not allowed"
  }
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
    $text = Read-Utf8Text $file.FullName
    foreach ($needle in $forbidden) {
      if ($text.Contains($needle)) {
        $relative = $file.FullName.Substring($resolvedRoot.Length).TrimStart("\", "/")
        Fail "hardcoded user-facing English text '$needle' found in $relative; route it through TextCatalog"
      }
    }
  }
}

if (-not (Test-Path -LiteralPath $rewardTablePath)) {
  Fail "missing reward table at app-LTL/src/data/reward-table.json"
}

try {
  $rewardTable = (Read-Utf8Text $rewardTablePath) | ConvertFrom-Json
}
catch {
  Fail "reward-table.json is not valid JSON: $($_.Exception.Message)"
}

$rewards = @(Get-Prop $rewardTable "rewards")
for ($i = 0; $i -lt $rewards.Count; $i++) {
  $reward = $rewards[$i]
  $rewardId = [string](Get-Prop $reward "id")
  if ([string]::IsNullOrWhiteSpace($rewardId)) {
    $rewardId = "rewards[$i]"
  }
  $text = Get-Prop $reward "text"
  Assert-LocalizedPair (Get-Prop $text "name") "reward-table.json:$rewardId.text.name"
  Assert-LocalizedPair (Get-Prop $text "description") "reward-table.json:$rewardId.text.description"
  Assert-ReadableKoreanValue ([string](Get-Prop (Get-Prop $text "name") "ko")) "reward-table.json:$rewardId.text.name.ko"
  Assert-ReadableKoreanValue ([string](Get-Prop (Get-Prop $text "description") "ko")) "reward-table.json:$rewardId.text.description.ko"

  $rarity = ([string](Get-Prop $reward "rarity")).ToLowerInvariant()
  if ($rarity -in @("epic", "legendary", "mythic")) {
    $payload = Get-Prop $reward "payload"
    $schema = Get-Prop $payload "effect_schema"
    Assert-LocalizedPair (Get-Prop $schema "summary_i18n") "reward-table.json:$rewardId.payload.effect_schema.summary_i18n"
    Assert-ReadableKoreanValue ([string](Get-Prop (Get-Prop $schema "summary_i18n") "ko")) "reward-table.json:$rewardId.payload.effect_schema.summary_i18n.ko"
  }
}

Write-Output "I18N_TEXT_GATE_OK"
exit 0
