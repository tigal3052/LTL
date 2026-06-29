$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$gatePath = Join-Path $repoRoot "LTL-harness/tools/runtime-size-gate.ps1"
$testRoot = Join-Path $repoRoot ".tmp-runtime-size-gate-tests"

function Assert-True($Condition, $Message) {
  if (-not $Condition) {
    throw $Message
  }
}

function Reset-TestRoot {
  $resolvedRepo = (Resolve-Path -LiteralPath $repoRoot).Path
  $targetFull = [System.IO.Path]::GetFullPath($testRoot)
  Assert-True ($targetFull.StartsWith($resolvedRepo, [System.StringComparison]::OrdinalIgnoreCase)) "refusing to clean outside repo: $targetFull"
  if (Test-Path -LiteralPath $targetFull) {
    Remove-Item -LiteralPath $targetFull -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $targetFull | Out-Null
}

function Remove-TestRoot {
  $resolvedRepo = (Resolve-Path -LiteralPath $repoRoot).Path
  $targetFull = [System.IO.Path]::GetFullPath($testRoot)
  Assert-True ($targetFull.StartsWith($resolvedRepo, [System.StringComparison]::OrdinalIgnoreCase)) "refusing to clean outside repo: $targetFull"
  if (Test-Path -LiteralPath $targetFull) {
    Remove-Item -LiteralPath $targetFull -Recurse -Force
  }
}

function Write-TestFile($Root, $RelativePath, $LineCount, $Prefix = "# line") {
  $path = Join-Path $Root $RelativePath
  $dir = Split-Path -Parent $path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $lines = for ($i = 1; $i -le $LineCount; $i++) { "$Prefix $i" }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, (($lines -join [Environment]::NewLine) + [Environment]::NewLine), $utf8NoBom)
}

function Write-Manifest($Root, $PathCaps, $GlobCaps, $LegacyDebtCaps = "") {
  $manifestPath = Join-Path $Root "docs/architectural-gates/runtime-size-gate.md"
  $manifestDir = Split-Path -Parent $manifestPath
  New-Item -ItemType Directory -Force -Path $manifestDir | Out-Null
  $lines = @(
    "date: 2026-06-11",
    "task: runtime-size-gate",
    "approval: approved",
    "",
    "profile: runtime-size",
    "purpose: Test manifest for the runtime-size gate.",
    ""
  )
  if (-not [string]::IsNullOrWhiteSpace($PathCaps)) {
    $lines += "strict_path_caps: $PathCaps"
  }
  if (-not [string]::IsNullOrWhiteSpace($GlobCaps)) {
    $lines += "strict_glob_caps: $GlobCaps"
  }
  if (-not [string]::IsNullOrWhiteSpace($LegacyDebtCaps)) {
    $lines += "legacy_debt_path_caps: $LegacyDebtCaps"
  }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($manifestPath, (($lines -join [Environment]::NewLine) + [Environment]::NewLine), $utf8NoBom)
}

function Invoke-RuntimeSizeGate($Root) {
  $args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $gatePath, "-Root", $Root)
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $output = & powershell @args 2>&1
  $ErrorActionPreference = $previousErrorActionPreference
  [PSCustomObject]@{
    Code = $LASTEXITCODE
    Output = ($output | Out-String)
  }
}

Assert-True (Test-Path -LiteralPath $gatePath) "runtime-size gate script is missing"

Reset-TestRoot

$passRoot = Join-Path $testRoot "pass"
Write-Manifest $passRoot `
  "app-LTL/src/MainControllerRuntime.gd=120; app-LTL/src/ui/MainViewRuntime.gd=180" `
  "app-LTL/src/ui/*.gd=100; app-LTL/src/scenes/pages/*.gd=220; app-LTL/src/ui/read_models/*.gd=250; app-LTL/src/ui/presenters/*.gd=150"
Write-TestFile $passRoot "app-LTL/src/MainControllerRuntime.gd" 100
Write-TestFile $passRoot "app-LTL/src/ui/MainViewRuntime.gd" 150
Write-TestFile $passRoot "app-LTL/src/ui/StatusPanelUI.gd" 80
Write-TestFile $passRoot "app-LTL/src/scenes/pages/CharacterSelectPage.gd" 200
Write-TestFile $passRoot "app-LTL/src/ui/read_models/RewardReadModel.gd" 240
Write-TestFile $passRoot "app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd" 90
$passResult = Invoke-RuntimeSizeGate $passRoot
Assert-True ($passResult.Code -eq 0) "strict pass case should succeed: $($passResult.Output)"
Assert-True ($passResult.Output -match "RUNTIME_SIZE_GATE_OK") "strict pass case should print marker"

$pathFailRoot = Join-Path $testRoot "path-fail"
Write-Manifest $pathFailRoot `
  "app-LTL/src/MainControllerRuntime.gd=120" `
  "app-LTL/src/ui/*.gd=100"
Write-TestFile $pathFailRoot "app-LTL/src/MainControllerRuntime.gd" 121
Write-TestFile $pathFailRoot "app-LTL/src/ui/StatusPanelUI.gd" 80
$pathFail = Invoke-RuntimeSizeGate $pathFailRoot
Assert-True ($pathFail.Code -ne 0) "strict path cap should fail when the owner grows beyond its cap"
Assert-True ($pathFail.Output -match "MainControllerRuntime") "strict path failure should mention the offending owner: $($pathFail.Output)"

$globFailRoot = Join-Path $testRoot "glob-fail"
Write-Manifest $globFailRoot `
  "app-LTL/src/MainControllerRuntime.gd=120; app-LTL/src/ui/MainViewRuntime.gd=180" `
  "app-LTL/src/ui/*.gd=100; app-LTL/src/scenes/pages/*.gd=220"
Write-TestFile $globFailRoot "app-LTL/src/MainControllerRuntime.gd" 100
Write-TestFile $globFailRoot "app-LTL/src/ui/MainViewRuntime.gd" 150
Write-TestFile $globFailRoot "app-LTL/src/scenes/pages/DefeatPage.gd" 221
$globFail = Invoke-RuntimeSizeGate $globFailRoot
Assert-True ($globFail.Code -ne 0) "strict glob cap should fail when a leaf grows beyond its cap"
Assert-True ($globFail.Output -match "DefeatPage") "strict glob failure should mention the offending leaf: $($globFail.Output)"

$missingOwnerRoot = Join-Path $testRoot "missing-owner"
Write-Manifest $missingOwnerRoot `
  "app-LTL/src/MainControllerRuntime.gd=120" `
  "app-LTL/src/ui/*.gd=100"
Write-TestFile $missingOwnerRoot "app-LTL/src/ui/StatusPanelUI.gd" 80
$missingOwner = Invoke-RuntimeSizeGate $missingOwnerRoot
Assert-True ($missingOwner.Code -ne 0) "missing strict owner path should fail"
Assert-True ($missingOwner.Output -match "MainControllerRuntime") "missing strict owner failure should name the missing file: $($missingOwner.Output)"

$legacyDebtPassRoot = Join-Path $testRoot "legacy-debt-pass"
Write-Manifest $legacyDebtPassRoot `
  "" `
  "app-LTL/src/**/*.gd=500; app-LTL/src/**/*.tscn=500" `
  "app-LTL/src/ui/BigLegacyOwner.gd=600"
Write-TestFile $legacyDebtPassRoot "app-LTL/src/ui/BigLegacyOwner.gd" 580
Write-TestFile $legacyDebtPassRoot "app-LTL/src/ui/NewLeaf.gd" 120
Write-TestFile $legacyDebtPassRoot "app-LTL/src/scenes/pages/CompactPage.tscn" 300
$legacyDebtPass = Invoke-RuntimeSizeGate $legacyDebtPassRoot
Assert-True ($legacyDebtPass.Code -eq 0) "legacy debt exact cap should pass while strict source/scene globs protect non-debt files: $($legacyDebtPass.Output)"

$legacyDebtGrowthRoot = Join-Path $testRoot "legacy-debt-growth"
Write-Manifest $legacyDebtGrowthRoot `
  "" `
  "app-LTL/src/**/*.gd=500" `
  "app-LTL/src/ui/BigLegacyOwner.gd=600"
Write-TestFile $legacyDebtGrowthRoot "app-LTL/src/ui/BigLegacyOwner.gd" 601
$legacyDebtGrowth = Invoke-RuntimeSizeGate $legacyDebtGrowthRoot
Assert-True ($legacyDebtGrowth.Code -ne 0) "legacy debt exact cap should fail when the owner grows beyond its frozen cap"
Assert-True ($legacyDebtGrowth.Output -match "BigLegacyOwner" -and $legacyDebtGrowth.Output -match "600") "legacy debt growth failure should name the owner and frozen cap: $($legacyDebtGrowth.Output)"

$sourceGlobFailRoot = Join-Path $testRoot "source-glob-fail"
Write-Manifest $sourceGlobFailRoot `
  "" `
  "app-LTL/src/**/*.gd=500; app-LTL/src/**/*.tscn=500"
Write-TestFile $sourceGlobFailRoot "app-LTL/src/ui/NewOversizedLeaf.gd" 501
$sourceGlobFail = Invoke-RuntimeSizeGate $sourceGlobFailRoot
Assert-True ($sourceGlobFail.Code -ne 0) "strict source glob should fail for a non-debt .gd file above 500 lines"
Assert-True ($sourceGlobFail.Output -match "NewOversizedLeaf") "strict source glob failure should name the oversized source file: $($sourceGlobFail.Output)"

$sceneGlobFailRoot = Join-Path $testRoot "scene-glob-fail"
Write-Manifest $sceneGlobFailRoot `
  "" `
  "app-LTL/src/**/*.tscn=500"
Write-TestFile $sceneGlobFailRoot "app-LTL/src/scenes/pages/OversizedPage.tscn" 501
$sceneGlobFail = Invoke-RuntimeSizeGate $sceneGlobFailRoot
Assert-True ($sceneGlobFail.Code -ne 0) "strict scene glob should fail for a non-debt .tscn file above 500 lines"
Assert-True ($sceneGlobFail.Output -match "OversizedPage") "strict scene glob failure should name the oversized scene file: $($sceneGlobFail.Output)"

Remove-TestRoot
Write-Output "RUNTIME_SIZE_GATE_TESTS_OK"
