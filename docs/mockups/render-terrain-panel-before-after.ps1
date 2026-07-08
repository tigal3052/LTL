$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function Get-RoundedRectPath {
    param(
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $Radius * 2
    $path.AddArc($X, $Y, $d, $d, 180, 90)
    $path.AddArc($X + $Width - $d, $Y, $d, $d, 270, 90)
    $path.AddArc($X + $Width - $d, $Y + $Height - $d, $d, $d, 0, 90)
    $path.AddArc($X, $Y + $Height - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

function Fill-RoundedRect {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Brush]$Brush,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )

    $path = Get-RoundedRectPath -X $X -Y $Y -Width $Width -Height $Height -Radius $Radius
    $Graphics.FillPath($Brush, $path)
    $path.Dispose()
}

function Draw-RoundedRect {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Pen]$Pen,
        [float]$X,
        [float]$Y,
        [float]$Width,
        [float]$Height,
        [float]$Radius
    )

    $path = Get-RoundedRectPath -X $X -Y $Y -Width $Width -Height $Height -Radius $Radius
    $Graphics.DrawPath($Pen, $path)
    $path.Dispose()
}

function Draw-Header {
    param(
        [System.Drawing.Graphics]$Graphics,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [string]$Title,
        [System.Drawing.Font]$Font,
        [System.Drawing.Brush]$TextBrush
    )

    $Graphics.DrawString($Title, $Font, $TextBrush, $X, $Y)
    $queueBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(152, 170, 185))
    $Graphics.DrawString("Queue", $Font, $queueBrush, $X + $Width - 210, $Y)
    $queueColors = @(
        [System.Drawing.Color]::FromArgb(204, 79, 79),
        [System.Drawing.Color]::FromArgb(67, 133, 206),
        [System.Drawing.Color]::FromArgb(82, 176, 95),
        [System.Drawing.Color]::FromArgb(143, 91, 199)
    )
    for ($i = 0; $i -lt $queueColors.Count; $i++) {
        $brush = New-Object System.Drawing.SolidBrush $queueColors[$i]
        $Graphics.FillRectangle($brush, $X + $Width - 138 + ($i * 28), $Y + 2, 18, 18)
        $brush.Dispose()
    }
    $queueBrush.Dispose()
}

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$mockupDir = Join-Path $root "docs\mockups"
$uiRoot = Join-Path $root "app-LTL\resources\UI"
$tileRoot = Join-Path $uiRoot "tile"
$outPath = Join-Path $mockupDir "terrain-panel-before-after-render.png"

$canvasWidth = 1800
$canvasHeight = 1120
$bmp = New-Object System.Drawing.Bitmap $canvasWidth, $canvasHeight
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$bgRect = New-Object System.Drawing.Rectangle 0, 0, $canvasWidth, $canvasHeight
$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $bgRect, ([System.Drawing.Color]::FromArgb(19, 31, 40)), ([System.Drawing.Color]::FromArgb(8, 13, 18)), 90
$g.FillRectangle($bgBrush, $bgRect)
$glowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(28, 82, 142, 192))
$g.FillEllipse($glowBrush, 520, -140, 760, 420)

$titleFont = New-Object System.Drawing.Font "Segoe UI", 28, ([System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font "Segoe UI", 13
$cardFont = New-Object System.Drawing.Font "Segoe UI", 18, ([System.Drawing.FontStyle]::Bold)
$bodyFont = New-Object System.Drawing.Font "Segoe UI", 10.5
$tagFont = New-Object System.Drawing.Font "Segoe UI", 9, ([System.Drawing.FontStyle]::Bold)
$whiteBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(239, 245, 251))
$mutedBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(154, 170, 183))

$g.DrawString("Terrain Panel Before / After Mockup", $titleFont, $whiteBrush, 70, 44)
$g.DrawString("tile_panel_nobg is now the strip background, and the color tiles render with their true non-square ratio.", $subFont, $mutedBrush, 72, 102)

$cardWidth = 790
$cardHeight = 850
$leftCardX = 70
$rightCardX = 910
$cardY = 170

function Draw-CardFrame {
    param(
        [System.Drawing.Graphics]$Graphics,
        [int]$X,
        [int]$Y,
        [string]$Title,
        [string]$Tag,
        [System.Drawing.Color]$TagBack,
        [System.Drawing.Color]$TagText,
        [System.Drawing.Font]$CardFont,
        [System.Drawing.Font]$TagFont,
        [System.Drawing.Brush]$TextBrush
    )

    $shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(110, 0, 0, 0))
    Fill-RoundedRect -Graphics $Graphics -Brush $shadowBrush -X ($X + 10) -Y ($Y + 18) -Width $cardWidth -Height $cardHeight -Radius 28
    $shadowBrush.Dispose()

    $cardBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(245, 21, 32, 40))
    Fill-RoundedRect -Graphics $Graphics -Brush $cardBrush -X $X -Y $Y -Width $cardWidth -Height $cardHeight -Radius 28
    $cardBrush.Dispose()

    $outlinePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(40, 198, 221, 239), 2)
    Draw-RoundedRect -Graphics $Graphics -Pen $outlinePen -X $X -Y $Y -Width $cardWidth -Height $cardHeight -Radius 28
    $outlinePen.Dispose()

    $headBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 28, 42, 52))
    Fill-RoundedRect -Graphics $Graphics -Brush $headBrush -X $X -Y $Y -Width $cardWidth -Height 74 -Radius 28
    $headBrush.Dispose()

    $Graphics.DrawString($Title, $CardFont, $TextBrush, $X + 28, $Y + 18)

    $tagBrush = New-Object System.Drawing.SolidBrush $TagBack
    Fill-RoundedRect -Graphics $Graphics -Brush $tagBrush -X ($X + 580) -Y ($Y + 20) -Width 178 -Height 32 -Radius 16
    $tagBrush.Dispose()
    $tagTextBrush = New-Object System.Drawing.SolidBrush $TagText
    $Graphics.DrawString($Tag, $TagFont, $tagTextBrush, $X + 595, $Y + 27)
    $tagTextBrush.Dispose()
}

Draw-CardFrame -Graphics $g -X $leftCardX -Y $cardY -Title "Before" -Tag "CURRENT FEEL" -TagBack ([System.Drawing.Color]::FromArgb(80, 92, 108, 120)) -TagText ([System.Drawing.Color]::FromArgb(214, 225, 235)) -CardFont $cardFont -TagFont $tagFont -TextBrush $whiteBrush
Draw-CardFrame -Graphics $g -X $rightCardX -Y $cardY -Title "After" -Tag "ASSET APPLIED" -TagBack ([System.Drawing.Color]::FromArgb(90, 156, 118, 46)) -TagText ([System.Drawing.Color]::FromArgb(255, 225, 160)) -CardFont $cardFont -TagFont $tagFont -TextBrush $whiteBrush

function Draw-InnerPanel {
    param([System.Drawing.Graphics]$Graphics, [int]$X, [int]$Y, [int]$Width, [int]$Height)
    $innerBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(90, 8, 12, 16))
    Fill-RoundedRect -Graphics $Graphics -Brush $innerBrush -X $X -Y $Y -Width $Width -Height $Height -Radius 24
    $innerBrush.Dispose()
    $innerPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(25, 255, 255, 255), 1)
    Draw-RoundedRect -Graphics $Graphics -Pen $innerPen -X $X -Y $Y -Width $Width -Height $Height -Radius 24
    $innerPen.Dispose()
}

function Draw-BeforeMockup {
    param([System.Drawing.Graphics]$Graphics, [int]$CardX, [int]$CardY)

    $innerX = $CardX + 18
    $innerY = $CardY + 92
    $innerW = $cardWidth - 36
    $innerH = 604
    Draw-InnerPanel -Graphics $Graphics -X $innerX -Y $innerY -Width $innerW -Height $innerH
    Draw-Header -Graphics $Graphics -X ($innerX + 20) -Y ($innerY + 16) -Width ($innerW - 40) -Title "Leviathan Crust Surface (3x10 Grid)" -Font $bodyFont -TextBrush $whiteBrush

    $boardW = $innerW - 40
    $boardH = [int]($boardW * 5.1 / 16)
    $boardX = $innerX + 20
    $boardY = $innerY + 110
    $boardRect = New-Object System.Drawing.Rectangle $boardX, $boardY, $boardW, $boardH
    $boardBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $boardRect, ([System.Drawing.Color]::FromArgb(43, 55, 66)), ([System.Drawing.Color]::FromArgb(20, 28, 34)), 90
    Fill-RoundedRect -Graphics $Graphics -Brush $boardBrush -X $boardX -Y $boardY -Width $boardW -Height $boardH -Radius 24
    $boardBrush.Dispose()
    $boardPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(30, 175, 201, 219), 2)
    Draw-RoundedRect -Graphics $Graphics -Pen $boardPen -X $boardX -Y $boardY -Width $boardW -Height $boardH -Radius 24
    $boardPen.Dispose()

    $drillRect = New-Object System.Drawing.Rectangle ($boardX - 18), ($boardY + 8), 148, 62
    $drillBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $drillRect, ([System.Drawing.Color]::FromArgb(98, 82, 66)), ([System.Drawing.Color]::FromArgb(54, 46, 40)), 90
    Fill-RoundedRect -Graphics $Graphics -Brush $drillBrush -X ($boardX - 18) -Y ($boardY + 8) -Width 148 -Height 62 -Radius 22
    $drillBrush.Dispose()
    $coreBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(130, 212, 255))
    $Graphics.FillEllipse($coreBrush, $boardX + 6, $boardY + 28, 16, 16)
    $coreBrush.Dispose()
    $beamRect = New-Object System.Drawing.Rectangle ($boardX + 116), ($boardY + 27), 70, 16
    $beamBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $beamRect, ([System.Drawing.Color]::FromArgb(128, 214, 255)), ([System.Drawing.Color]::FromArgb(186, 238, 255)), 0
    $Graphics.FillRectangle($beamBrush, $beamRect)
    $beamBrush.Dispose()

    $colors = @("red","blue","green","purple","red","green","blue","purple","red","blue","green","purple","red","blue","green","purple","red","blue","green","purple","blue","red","purple","green","blue","red","purple","green","blue","red")
    $cellGap = 8
    $padX = 14
    $padY = 18
    $cellW = [math]::Floor(($boardW - ($padX * 2) - ($cellGap * 9)) / 10)
    $cellH = [math]::Floor(($boardH - ($padY * 2) - ($cellGap * 2)) / 3)
    foreach ($i in 0..29) {
        $row = [math]::Floor($i / 10)
        $column = $i % 10
        $cellX = $boardX + $padX + $column * ($cellW + $cellGap)
        $cellY = $boardY + $padY + $row * ($cellH + $cellGap)
        switch ($colors[$i]) {
            "red" {
                $topColor = [System.Drawing.Color]::FromArgb(118, 64, 64)
                $bottomColor = [System.Drawing.Color]::FromArgb(74, 38, 38)
            }
            "blue" {
                $topColor = [System.Drawing.Color]::FromArgb(65, 101, 141)
                $bottomColor = [System.Drawing.Color]::FromArgb(39, 64, 93)
            }
            "green" {
                $topColor = [System.Drawing.Color]::FromArgb(70, 115, 77)
                $bottomColor = [System.Drawing.Color]::FromArgb(41, 72, 45)
            }
            default {
                $topColor = [System.Drawing.Color]::FromArgb(107, 77, 134)
                $bottomColor = [System.Drawing.Color]::FromArgb(64, 45, 82)
            }
        }

        $cellRect = New-Object System.Drawing.Rectangle $cellX, $cellY, $cellW, $cellH
        $cellBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $cellRect, $topColor, $bottomColor, 90
        Fill-RoundedRect -Graphics $Graphics -Brush $cellBrush -X $cellX -Y $cellY -Width $cellW -Height $cellH -Radius 10
        $cellBrush.Dispose()
        $cellPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(36, 210, 224, 235), 1)
        Draw-RoundedRect -Graphics $Graphics -Pen $cellPen -X $cellX -Y $cellY -Width $cellW -Height $cellH -Radius 10
        $cellPen.Dispose()

        $diamond = New-Object "System.Drawing.PointF[]" 4
        $diamond[0] = New-Object System.Drawing.PointF ($cellX + $cellW * 0.5), ($cellY + $cellH * 0.25)
        $diamond[1] = New-Object System.Drawing.PointF ($cellX + $cellW * 0.6), ($cellY + $cellH * 0.5)
        $diamond[2] = New-Object System.Drawing.PointF ($cellX + $cellW * 0.5), ($cellY + $cellH * 0.75)
        $diamond[3] = New-Object System.Drawing.PointF ($cellX + $cellW * 0.4), ($cellY + $cellH * 0.5)
        $diamondBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 242, 246, 248))
        $Graphics.FillPolygon($diamondBrush, $diamond)
        $diamondBrush.Dispose()
    }

    $Graphics.DrawString("Before: abstract cells are readable, but the miner and terrain still feel disconnected.", $bodyFont, $mutedBrush, $CardX + 28, $CardY + $cardHeight - 116)
    $Graphics.DrawString("The miner also has no protected silhouette range in the current composition.", $bodyFont, $mutedBrush, $CardX + 28, $CardY + $cardHeight - 82)
}

function Draw-AfterMockup {
    param([System.Drawing.Graphics]$Graphics, [int]$CardX, [int]$CardY)

    $panelImage = [System.Drawing.Image]::FromFile((Join-Path $tileRoot "tile_panel_nobg.png"))
    $minerImage = [System.Drawing.Image]::FromFile((Join-Path $uiRoot "miner.png"))
    $tileImages = @{
        red = [System.Drawing.Image]::FromFile((Join-Path $tileRoot "red_tile.png"))
        blue = [System.Drawing.Image]::FromFile((Join-Path $tileRoot "blue_tile.png"))
        green = [System.Drawing.Image]::FromFile((Join-Path $tileRoot "green_tile.png"))
        purple = [System.Drawing.Image]::FromFile((Join-Path $tileRoot "purple_tile.png"))
    }

    try {
        $innerX = $CardX + 18
        $innerY = $CardY + 92
        $innerW = $cardWidth - 36
        $innerH = 604
        Draw-InnerPanel -Graphics $Graphics -X $innerX -Y $innerY -Width $innerW -Height $innerH
        Draw-Header -Graphics $Graphics -X ($innerX + 20) -Y ($innerY + 16) -Width ($innerW - 40) -Title "Leviathan Crust Surface (3x10 Grid)" -Font $bodyFont -TextBrush $whiteBrush

        $boardW = $innerW - 40
        $boardH = [int]($boardW * 5.1 / 16)
        $boardX = $innerX + 20
        $boardY = $innerY + 110

        $minerW = [int]($boardW * 0.285)
        $minerH = [int](($minerW / $minerImage.Width) * $minerImage.Height)
        $minerCanvas = New-Object System.Drawing.Bitmap $minerW, $minerH
        $minerGraphics = [System.Drawing.Graphics]::FromImage($minerCanvas)
        $minerGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $minerGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $minerGraphics.DrawImage($minerImage, 0, 0, $minerW, $minerH)
        $minerGraphics.Dispose()

        $Graphics.TranslateTransform($boardX + [int]($boardW * 0.12), $boardY + [int]($boardH * 0.22))
        $Graphics.RotateTransform(-4.5)
        $Graphics.DrawImage($minerCanvas, -[int]($minerW * 0.58), -[int]($minerH * 0.34), $minerW, $minerH)
        $Graphics.ResetTransform()

        $shellX = $boardX + [int]($boardW * 0.214)
        $shellY = $boardY + [int]($boardH * 0.12)
        $shellW = [int]($boardW * 0.75)
        $shellH = [int]($boardH * 0.84)
        $panelDestRect = New-Object System.Drawing.Rectangle $shellX, $shellY, $shellW, $shellH
        $panelSrcRect = New-Object System.Drawing.Rectangle 27, 128, 1384, 188
        $Graphics.DrawImage($panelImage, $panelDestRect, $panelSrcRect, [System.Drawing.GraphicsUnit]::Pixel)

        $laneInsetX = [int]($shellW * 0.024)
        $laneInsetY = [int]($shellH * 0.125)
        $laneGapY = [int]($shellH * 0.045)
        $laneHeight = [math]::Floor(($shellH - ($laneInsetY * 2) - ($laneGapY * 2)) / 3)
        $laneWidth = $shellW - ($laneInsetX * 2)
        $laneBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(236, 14, 24, 33))
        for ($rowIndex = 0; $rowIndex -lt 3; $rowIndex++) {
            $laneY = $shellY + $laneInsetY + $rowIndex * ($laneHeight + $laneGapY)
            Fill-RoundedRect -Graphics $Graphics -Brush $laneBrush -X ($shellX + $laneInsetX) -Y $laneY -Width $laneWidth -Height $laneHeight -Radius 8
        }
        $laneBrush.Dispose()

        $gridPadX = [int]($shellW * 0.026)
        $gridPadY = [int]($shellH * 0.112)
        $slotGapX = 3
        $slotGapY = [int]($shellH * 0.032)
        $slotW = [math]::Floor(($shellW - ($gridPadX * 2) - ($slotGapX * 9)) / 10)
        $slotH = [math]::Floor(($shellH - ($gridPadY * 2) - ($slotGapY * 2)) / 3)
        $tileOrder = @("red","blue","green","purple","red","green","blue","purple","red","blue","green","purple","red","blue","green","purple","red","blue","green","purple","blue","red","purple","green","blue","red","purple","green","blue","red")
        foreach ($i in 0..29) {
            $row = [math]::Floor($i / 10)
            $column = $i % 10
            $slotX = $shellX + $gridPadX + $column * ($slotW + $slotGapX)
            $slotY = $shellY + $gridPadY + $row * ($slotH + $slotGapY)
            $tileImage = $tileImages[$tileOrder[$i]]
            $tileScale = [math]::Min((($slotW * 0.8541667) / $tileImage.Width), (($slotH * 0.8571429) / $tileImage.Height))
            $tileW = [math]::Floor($tileImage.Width * $tileScale)
            $tileH = [math]::Floor($tileImage.Height * $tileScale)
            $tileX = $slotX + [int](($slotW - $tileW) / 2)
            $tileY = $slotY + [int](($slotH - $tileH) / 2)
            $Graphics.DrawImage($tileImage, $tileX, $tileY, $tileW, $tileH)
        }

        $Graphics.DrawString("After: tile_panel_nobg acts as the background shell and the miner stays close without the anchor label.", $bodyFont, $mutedBrush, $CardX + 28, $CardY + $cardHeight - 116)
        $Graphics.DrawString("Color tiles now render in a non-square size derived from the real slot width and height.", $bodyFont, $mutedBrush, $CardX + 28, $CardY + $cardHeight - 82)

        $minerCanvas.Dispose()
    }
    finally {
        $panelImage.Dispose()
        $minerImage.Dispose()
        foreach ($tileImage in $tileImages.Values) {
            $tileImage.Dispose()
        }
    }
}

Draw-BeforeMockup -Graphics $g -CardX $leftCardX -CardY $cardY
Draw-AfterMockup -Graphics $g -CardX $rightCardX -CardY $cardY

$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
$bgBrush.Dispose()
$glowBrush.Dispose()
$titleFont.Dispose()
$subFont.Dispose()
$cardFont.Dispose()
$bodyFont.Dispose()
$tagFont.Dispose()
$whiteBrush.Dispose()
$mutedBrush.Dispose()

Write-Output $outPath
