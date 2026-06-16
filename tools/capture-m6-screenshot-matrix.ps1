param(
  [string]$WorkspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$ProjectPath = "app-LTL",
  [string]$GodotPath = "D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64.exe",
  [string]$HoldScript = "tests/run_m6_visual_hold.gd",
  [string]$OutputDirectory = "docs/evidence/m6-screenshot-matrix/2026-06-15",
  [string[]]$Viewports = @("1280x720", "1440x900", "1680x1050", "1920x1080"),
  [string[]]$Pages = @("character_select", "leviathan_select", "node_select", "battle", "reward", "defeat"),
  [int]$WindowReadyTimeoutSeconds = 25,
  [int]$SettleDelaySeconds = 2
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
  param([System.Diagnostics.Process]$Process)
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

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class LtlClientCapture {
  [StructLayout(LayoutKind.Sequential)]
  public struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
  }

  [StructLayout(LayoutKind.Sequential)]
  public struct POINT {
    public int X;
    public int Y;
  }

  [DllImport("user32.dll")]
  public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);

  [DllImport("user32.dll")]
  public static extern bool ClientToScreen(IntPtr hWnd, ref POINT point);

  [DllImport("user32.dll")]
  public static extern bool SetForegroundWindow(IntPtr hWnd);

  [DllImport("user32.dll")]
  public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

  [DllImport("user32.dll")]
  public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
}
"@

$hwndTopMost = [System.IntPtr](-1)
$hwndNoTopMost = [System.IntPtr](-2)
$swpNoMove = 0x0002
$swpNoSize = 0x0001
$swpShowWindow = 0x0040

$projectRoot = Resolve-AbsolutePath -BasePath $WorkspaceRoot -CandidatePath $ProjectPath
$outputRoot = Resolve-AbsolutePath -BasePath $WorkspaceRoot -CandidatePath $OutputDirectory
[System.IO.Directory]::CreateDirectory($outputRoot) | Out-Null

foreach ($viewport in $Viewports) {
  foreach ($page in $Pages) {
    $outputPath = Join-Path $outputRoot "$page`_$viewport.png"
    $process = Start-Process -FilePath $GodotPath -ArgumentList @(
      "--path", $projectRoot,
      "--script", $HoldScript,
      "--",
      "--page=$page",
      "--viewport=$viewport"
    ) -PassThru

    try {
      $deadline = (Get-Date).AddSeconds($WindowReadyTimeoutSeconds)
      $mainWindowHandle = 0
      do {
        Start-Sleep -Milliseconds 500
        $mainWindowHandle = Get-MainWindowHandleValue -Process $process
      } while ($mainWindowHandle -eq 0 -and -not $process.HasExited -and (Get-Date) -lt $deadline)

      if ($mainWindowHandle -eq 0) {
        if ($process.HasExited) {
          throw "Godot exited before the M6 visual-hold window became ready for $page $viewport."
        }
        throw "Godot window did not become ready within $WindowReadyTimeoutSeconds seconds for $page $viewport."
      }

      [LtlClientCapture]::ShowWindow([System.IntPtr]$mainWindowHandle, 9) | Out-Null
      [LtlClientCapture]::SetWindowPos([System.IntPtr]$mainWindowHandle, $hwndTopMost, 0, 0, 0, 0, ($swpNoMove -bor $swpNoSize -bor $swpShowWindow)) | Out-Null
      [LtlClientCapture]::SetForegroundWindow([System.IntPtr]$mainWindowHandle) | Out-Null
      Start-Sleep -Milliseconds 300
      [LtlClientCapture]::SetWindowPos([System.IntPtr]$mainWindowHandle, $hwndNoTopMost, 0, 0, 0, 0, ($swpNoMove -bor $swpNoSize -bor $swpShowWindow)) | Out-Null
      Start-Sleep -Seconds $SettleDelaySeconds

      $rect = New-Object LtlClientCapture+RECT
      if (-not [LtlClientCapture]::GetClientRect([System.IntPtr]$mainWindowHandle, [ref]$rect)) {
        throw "GetClientRect failed for $page $viewport."
      }
      $origin = New-Object LtlClientCapture+POINT
      $origin.X = 0
      $origin.Y = 0
      if (-not [LtlClientCapture]::ClientToScreen([System.IntPtr]$mainWindowHandle, [ref]$origin)) {
        throw "ClientToScreen failed for $page $viewport."
      }

      $width = $rect.Right - $rect.Left
      $height = $rect.Bottom - $rect.Top
      if ($width -le 0 -or $height -le 0) {
        throw "Godot client area reported a non-positive capture size for $page $viewport`: ${width}x${height}."
      }

      $bitmap = New-Object System.Drawing.Bitmap $width, $height
      $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
      try {
        $graphics.CopyFromScreen($origin.X, $origin.Y, 0, 0, $bitmap.Size)
        $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
      }
      finally {
        $graphics.Dispose()
        $bitmap.Dispose()
      }

      Write-Output "M6_SCREENSHOT_CAPTURED $outputPath"
    }
    finally {
      if ($process -and -not $process.HasExited) {
        $process.CloseMainWindow() | Out-Null
        Start-Sleep -Milliseconds 700
        if (-not $process.HasExited) {
          Stop-Process -Id $process.Id -Force
        }
      }
      Start-Sleep -Milliseconds 800
    }
  }
}

Write-Output "M6_SCREENSHOT_MATRIX_CAPTURE_OK $outputRoot"
