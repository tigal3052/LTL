param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$ProjectPath = "app-LTL",
  [string]$GodotPath = "D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe",
  [string]$HoldScript = "tests/run_node_select_visual_hold.gd",
  [string]$OutputPath = "test-artifacts/visual/node-select-runtime.png",
  [int]$WindowReadyTimeoutSeconds = 20,
  [int]$SettleDelaySeconds = 3
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

function Get-MainWindowHandleValue {
  param(
    [System.Diagnostics.Process]$Process
  )

  if ($null -eq $Process) {
    return 0
  }

  $Process.Refresh()
  if ($Process.HasExited) {
    return 0
  }

  try {
    return [int64]$Process.MainWindowHandle
  }
  catch {
    return 0
  }
}

$projectRoot = Resolve-AbsolutePath -BasePath $WorkspaceRoot -CandidatePath $ProjectPath
$outputPath = Resolve-AbsolutePath -BasePath $projectRoot -CandidatePath $OutputPath

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class LtlWindowCapture {
  [StructLayout(LayoutKind.Sequential)]
  public struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
  }

  [DllImport("user32.dll")]
  public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
}
"@

$process = Start-Process -FilePath $GodotPath -ArgumentList @("--path", $projectRoot, "--script", $HoldScript) -PassThru

try {
  $deadline = (Get-Date).AddSeconds($WindowReadyTimeoutSeconds)
  $mainWindowHandle = 0
  do {
    Start-Sleep -Milliseconds 500
    $mainWindowHandle = Get-MainWindowHandleValue -Process $process
  } while ($mainWindowHandle -eq 0 -and -not $process.HasExited -and (Get-Date) -lt $deadline)

  if ($mainWindowHandle -eq 0) {
    if ($process.HasExited) {
      throw "Godot process exited before the visual-hold window became ready."
    }
    throw "Godot window did not become ready within $WindowReadyTimeoutSeconds seconds."
  }

  Start-Sleep -Seconds $SettleDelaySeconds

  $rect = New-Object LtlWindowCapture+RECT
  if (-not [LtlWindowCapture]::GetWindowRect([System.IntPtr]$mainWindowHandle, [ref]$rect)) {
    throw "GetWindowRect failed for the live Godot window."
  }

  $width = $rect.Right - $rect.Left
  $height = $rect.Bottom - $rect.Top
  if ($width -le 0 -or $height -le 0) {
    throw "Live Godot window reported a non-positive capture size: ${width}x${height}."
  }

  $outputDirectory = [System.IO.Path]::GetDirectoryName($outputPath)
  [System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null

  $bitmap = New-Object System.Drawing.Bitmap $width, $height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  try {
    $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
  }
  finally {
    $graphics.Dispose()
    $bitmap.Dispose()
  }

  Write-Output "NODE_SELECT_RUNTIME_CAPTURE_OK $outputPath"
}
finally {
  if ($process -and -not $process.HasExited) {
    $process.CloseMainWindow() | Out-Null
    Start-Sleep -Seconds 1
    if (-not $process.HasExited) {
      Stop-Process -Id $process.Id -Force
    }
  }
}
