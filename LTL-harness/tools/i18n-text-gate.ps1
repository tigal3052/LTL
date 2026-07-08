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
$catalogKoPath = Join-Path $resolvedRoot "app-LTL/src/data/i18n/text-ko.json"
$catalogEnPath = Join-Path $resolvedRoot "app-LTL/src/data/i18n/text-en.json"
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

if (-not (Test-Path -LiteralPath $catalogKoPath)) {
  Fail "missing Korean locale catalog at app-LTL/src/data/i18n/text-ko.json"
}

if (-not (Test-Path -LiteralPath $catalogEnPath)) {
  Fail "missing English locale catalog at app-LTL/src/data/i18n/text-en.json"
}

$catalogSource = Read-Utf8Text $catalogPath
if (-not $catalogSource.Contains("text-ko.json") -or -not $catalogSource.Contains("text-en.json")) {
  Fail "TextCatalog.gd must route localized UI strings through text-ko.json and text-en.json"
}

try {
  $koCatalog = (Read-Utf8Text $catalogKoPath) | ConvertFrom-Json
}
catch {
  Fail "text-ko.json is not valid JSON: $($_.Exception.Message)"
}

try {
  $enCatalog = (Read-Utf8Text $catalogEnPath) | ConvertFrom-Json
}
catch {
  Fail "text-en.json is not valid JSON: $($_.Exception.Message)"
}

Assert-ReadableKoreanValue ([string](Get-Prop (Get-Prop $koCatalog "strings") "action.start")) "text-ko.json:strings.action.start"
Assert-ReadableKoreanValue ([string](Get-Prop (Get-Prop $koCatalog "strings") "settings.title")) "text-ko.json:strings.settings.title"
Assert-ReadableKoreanValue ([string](Get-Prop (Get-Prop (Get-Prop $koCatalog "characters") "miner") "name")) "text-ko.json:characters.miner.name"
Assert-ReadableKoreanValue ([string](Get-Prop (Get-Prop (Get-Prop $koCatalog "leviathans") "ossuary_tortoise") "name")) "text-ko.json:leviathans.ossuary_tortoise.name"
Assert-ReadableKoreanValue ([string](Get-Prop (Get-Prop (Get-Prop $koCatalog "baseShop") "character_engineer") "label")) "text-ko.json:baseShop.character_engineer.label"

if ([string]::IsNullOrWhiteSpace([string](Get-Prop (Get-Prop $enCatalog "strings") "action.start"))) {
  Fail "text-en.json:strings.action.start must define a non-empty English label"
}

if ([string]::IsNullOrWhiteSpace([string](Get-Prop (Get-Prop $enCatalog "strings") "settings.title"))) {
  Fail "text-en.json:strings.settings.title must define a non-empty English label"
}

$scanRoots = @(
  "app-LTL/src"
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
  "Stage ",
  "Reduced Flash",
  "Reduced Particles",
  "Hold-Fire Assist",
  "PASSIVE TREE",
  "BASE UNLOCKS",
  "LOOTING TARGET",
  "Repair locked",
  "Field:",
  "Looting Start",
  "DEFEAT PAGE",
  "GAME OVER",
  "The contract broke.",
  "Try a safer opening route before chasing deeper rewards.",
  "Front Color:",
  "Contract Runner",
  "Unknown Item",
  "unknown waters",
  "salt shell",
  "Durability "
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
    $relative = $file.FullName.Substring($resolvedRoot.Length).TrimStart("\", "/")

    foreach ($needle in $forbidden) {
      if ($text.Contains($needle)) {
        Fail "hardcoded user-facing English text '$needle' found in $relative; route it through TextCatalog"
      }
    }

    if ($file.Extension -eq ".gd") {
      $logLines = $text -split "`r?`n"
      foreach ($logLine in $logLines) {
        if ($logLine -match 'view\.add_log\(\s*"' -and $logLine -notmatch 'TextCatalogScript\.t\(') {
          Fail "direct hardcoded log copy found in $relative via view.add_log; route it through TextCatalog before logging"
        }
        if ($logLine -match 'locale\s*==\s*"(ko|en)"' -and $logLine -match '"[^"]*([A-Za-z]{3,}|[\uAC00-\uD7A3])[^"]*".*"[^"]*([A-Za-z]{3,}|[\uAC00-\uD7A3])[^"]*"' -and $logLine -notmatch 'TextCatalogScript\.t\(') {
          Fail "inline locale-branch copy found in $relative; route ko/en strings through TextCatalog JSON instead of file-local ternaries"
        }
        if ($logLine -match '"(pageEyebrow|pageTitle|pageSubtitle|pageBoardTitle|pageBoardHint|pageCause|pageTip|pageButtonText|targetLabel|runStructure)"\s*:\s*"[^"]*[\p{L}]') {
          Fail "hardcoded page-model copy found in $relative; supply localized values from TextCatalog-backed runtime data"
        }
      }
      if ([regex]::IsMatch($text, 'func\s+_localized\s*\(')) {
        Fail "inline locale helper found in $relative; route copy through TextCatalog JSON instead of file-local ko/en pairs"
      }
      if ([regex]::IsMatch($text, '@export\s+var\s+default_(eyebrow|title|subtitle|description|button_text|board_title|board_hint|cause|tip)\s*:=\s*"[^"]*[\p{L}]')) {
        Fail "player-facing default copy found in $relative; leave scene-script defaults blank and supply text from TextCatalog-backed scene models"
      }
      continue
    }

    $lines = $text -split "`r?`n"
    foreach ($line in $lines) {
      if ($line -match '^\s*(text|default_(eyebrow|title|subtitle|description|button_text|board_title|board_hint|cause|tip|badge|kicker))\s*=\s*"(?<value>.*)$') {
        $value = $Matches["value"]
        if ($value -match '[\p{L}]') {
          Fail "static scene text found in $relative; clear scene defaults and populate them from TextCatalog at runtime"
        }
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
