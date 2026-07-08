param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$ProjectPath = "app-LTL",
  [string]$GodotPath = "D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe",
  [string]$CaptureScript = "tests/run_m6_visual_capture.gd",
  [string]$OutputDirectory = "docs/evidence/m6-screenshot-matrix/2026-06-15",
  [string[]]$Viewports = @("1280x720", "1440x900", "1680x1050", "1920x1080"),
  [string[]]$Pages = @("character_select", "leviathan_select", "node_select", "battle", "reward", "defeat")
)

$ErrorActionPreference = "Stop"

function Resolve-AbsolutePath {
  param(
    [string]$BasePath,
    [string]$CandidatePath
  )
  if ([System.IO.Path]::IsPathRooted($CandidatePath)) {
    return [System.IO.Path]::GetFullPath($CandidatePath)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $BasePath $CandidatePath))
}

$projectRoot = Resolve-AbsolutePath -BasePath $WorkspaceRoot -CandidatePath $ProjectPath
$outputRoot = Resolve-AbsolutePath -BasePath $WorkspaceRoot -CandidatePath $OutputDirectory
[System.IO.Directory]::CreateDirectory($outputRoot) | Out-Null

foreach ($viewport in $Viewports) {
  foreach ($page in $Pages) {
    $outputPath = Join-Path $outputRoot "$page`_$viewport.png"
    $logPath = Join-Path $outputRoot "$page`_$viewport.log"
    $arguments = @(
      "--path", $projectRoot,
      "--script", $CaptureScript,
      "--log-file", $logPath,
      "--",
      "--page=$page",
      "--viewport=$viewport",
      "--output=$outputPath"
    )
    $commandOutput = & $GodotPath @arguments 2>&1
    $joined = ($commandOutput | ForEach-Object { "$_" }) -join [Environment]::NewLine
    $logText = ""
    $hasSuccessMarker = $false
    $hasOutputFile = $false
    for ($i = 0; $i -lt 12; $i++) {
      if (Test-Path $logPath) {
        $logText = Get-Content -LiteralPath $logPath -Raw
      }
      $hasSuccessMarker = ($joined -match "M6_INTERNAL_CAPTURED") -or ($logText -match "M6_INTERNAL_CAPTURED")
      $hasOutputFile = Test-Path $outputPath
      if ($hasSuccessMarker -and $hasOutputFile) {
        break
      }
      Start-Sleep -Milliseconds 250
    }
    if (-not ($hasSuccessMarker -and $hasOutputFile)) {
      if ([string]::IsNullOrWhiteSpace($joined)) {
        $joined = $logText
      }
      throw "Godot internal capture failed for $page $viewport.$([Environment]::NewLine)$joined"
    }
    foreach ($line in $commandOutput) {
      $text = "$line"
      if ($text -match "M6_INTERNAL_CAPTURED" -or $text -match "Godot Engine" -or $text -match "OpenGL API") {
        Write-Output $text
      }
    }
    if (-not [string]::IsNullOrWhiteSpace($logText) -and ($commandOutput | Measure-Object).Count -eq 0) {
      foreach ($line in ($logText -split "`r?`n")) {
        if ($line -match "M6_INTERNAL_CAPTURED" -or $line -match "Godot Engine" -or $line -match "OpenGL API") {
          Write-Output $line
        }
      }
    }
  }
}

Write-Output "M6_SCREENSHOT_MATRIX_CAPTURE_OK $outputRoot"
