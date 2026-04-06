$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Add-Type -AssemblyName System.Drawing

function New-RoundedPath {
  param(
    [System.Drawing.RectangleF] $Rect,
    [float] $Radius
  )

  $diameter = $Radius * 2
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddArc($Rect.X, $Rect.Y, $diameter, $diameter, 180, 90)
  $path.AddArc($Rect.Right - $diameter, $Rect.Y, $diameter, $diameter, 270, 90)
  $path.AddArc($Rect.Right - $diameter, $Rect.Bottom - $diameter, $diameter, $diameter, 0, 90)
  $path.AddArc($Rect.X, $Rect.Bottom - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()
  return $path
}

function New-StarPoints {
  param(
    [float] $CenterX,
    [float] $CenterY,
    [float] $OuterRadius,
    [float] $InnerRadius
  )

  $points = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
  for ($index = 0; $index -lt 8; $index++) {
    $angle = (-90 + ($index * 45)) * [Math]::PI / 180
    $radius = if ($index % 2 -eq 0) { $OuterRadius } else { $InnerRadius }
    $x = $CenterX + ([Math]::Cos($angle) * $radius)
    $y = $CenterY + ([Math]::Sin($angle) * $radius)
    $points.Add([System.Drawing.PointF]::new([float] $x, [float] $y))
  }
  return $points.ToArray()
}

function New-Canvas {
  param(
    [int] $Size,
    [bool] $Transparent = $false
  )

  $bitmap = New-Object System.Drawing.Bitmap $Size, $Size
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  if ($Transparent) {
    $graphics.Clear([System.Drawing.Color]::Transparent)
  }
  return @{
    Bitmap = $bitmap
    Graphics = $graphics
  }
}

function Draw-Glow {
  param(
    [System.Drawing.Graphics] $Graphics,
    [System.Drawing.RectangleF] $Rect,
    [System.Drawing.Color] $CenterColor
  )

  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddEllipse($Rect)
  $brush = New-Object System.Drawing.Drawing2D.PathGradientBrush $path
  $brush.CenterColor = $CenterColor
  $brush.SurroundColors = @([System.Drawing.Color]::Transparent)
  $Graphics.FillPath($brush, $path)
  $brush.Dispose()
  $path.Dispose()
}

function Draw-MainMark {
  param(
    [System.Drawing.Graphics] $Graphics,
    [int] $Size
  )

  $cardSize = $Size * 0.56
  $cardX = ($Size - $cardSize) / 2
  $cardY = ($Size - $cardSize) / 2
  $cardRect = [System.Drawing.RectangleF]::new([float] $cardX, [float] $cardY, [float] $cardSize, [float] $cardSize)
  $cardPath = New-RoundedPath -Rect $cardRect -Radius ($Size * 0.11)

  $cardBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.PointF]::new([float] $cardRect.Left, [float] $cardRect.Top),
    [System.Drawing.PointF]::new([float] $cardRect.Right, [float] $cardRect.Bottom),
    [System.Drawing.Color]::FromArgb(245, 34, 10, 62),
    [System.Drawing.Color]::FromArgb(245, 13, 27, 62)
  )
  $Graphics.FillPath($cardBrush, $cardPath)
  $cardBrush.Dispose()

  $cardBorder = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(160, 185, 122, 232)), ($Size * 0.012)
  $Graphics.DrawPath($cardBorder, $cardPath)
  $cardBorder.Dispose()

  $orbitPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(210, 34, 211, 238)), ($Size * 0.022)
  $orbitPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $orbitPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $orbitRect = [System.Drawing.RectangleF]::new(
    [float] ($cardRect.Left + ($cardRect.Width * 0.18)),
    [float] ($cardRect.Top + ($cardRect.Height * 0.58)),
    [float] ($cardRect.Width * 0.64),
    [float] ($cardRect.Height * 0.26)
  )
  $Graphics.DrawArc($orbitPen, $orbitRect, 10, 170)
  $orbitPen.Dispose()

  $starBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 255, 255))
  $mainStar = New-StarPoints -CenterX ($cardRect.Left + ($cardRect.Width * 0.44)) -CenterY ($cardRect.Top + ($cardRect.Height * 0.46)) -OuterRadius ($Size * 0.09) -InnerRadius ($Size * 0.034)
  $Graphics.FillPolygon($starBrush, $mainStar)
  $miniStarA = New-StarPoints -CenterX ($cardRect.Left + ($cardRect.Width * 0.70)) -CenterY ($cardRect.Top + ($cardRect.Height * 0.34)) -OuterRadius ($Size * 0.04) -InnerRadius ($Size * 0.014)
  $Graphics.FillPolygon($starBrush, $miniStarA)
  $miniStarB = New-StarPoints -CenterX ($cardRect.Left + ($cardRect.Width * 0.67)) -CenterY ($cardRect.Top + ($cardRect.Height * 0.58)) -OuterRadius ($Size * 0.03) -InnerRadius ($Size * 0.011)
  $Graphics.FillPolygon($starBrush, $miniStarB)
  $starBrush.Dispose()

  $cardPath.Dispose()
}

function Draw-FullIcon {
  param(
    [System.Drawing.Graphics] $Graphics,
    [int] $Size
  )

  $rect = [System.Drawing.RectangleF]::new(0, 0, $Size, $Size)
  $backgroundBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.PointF]::new(0, 0),
    [System.Drawing.PointF]::new([float] $Size, [float] $Size),
    [System.Drawing.Color]::FromArgb(255, 15, 10, 32),
    [System.Drawing.Color]::FromArgb(255, 10, 10, 20)
  )
  $Graphics.FillRectangle($backgroundBrush, $rect)
  $backgroundBrush.Dispose()

  Draw-Glow -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new([float] ($Size * 0.48), [float] ($Size * 0.10), [float] ($Size * 0.44), [float] ($Size * 0.44))) -CenterColor ([System.Drawing.Color]::FromArgb(115, 224, 64, 251))
  Draw-Glow -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new([float] ($Size * 0.04), [float] ($Size * 0.50), [float] ($Size * 0.42), [float] ($Size * 0.42))) -CenterColor ([System.Drawing.Color]::FromArgb(90, 34, 211, 238))

  $ringPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(125, 185, 122, 232)), ($Size * 0.014)
  $ringPen.Alignment = [System.Drawing.Drawing2D.PenAlignment]::Inset
  $ringRect = [System.Drawing.RectangleF]::new([float] ($Size * 0.08), [float] ($Size * 0.08), [float] ($Size * 0.84), [float] ($Size * 0.84))
  $Graphics.DrawEllipse($ringPen, $ringRect)
  $ringPen.Dispose()

  Draw-MainMark -Graphics $Graphics -Size $Size
}

function Draw-LaunchMark {
  param(
    [System.Drawing.Graphics] $Graphics,
    [int] $Size
  )

  Draw-Glow -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new([float] ($Size * 0.22), [float] ($Size * 0.20), [float] ($Size * 0.56), [float] ($Size * 0.56))) -CenterColor ([System.Drawing.Color]::FromArgb(85, 123, 47, 190))
  Draw-MainMark -Graphics $Graphics -Size $Size
}

function Save-ScaledPng {
  param(
    [System.Drawing.Bitmap] $Source,
    [int] $Width,
    [int] $Height,
    [string] $Path
  )

  $target = New-Object System.Drawing.Bitmap $Width, $Height
  $graphics = [System.Drawing.Graphics]::FromImage($target)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.DrawImage($Source, 0, 0, $Width, $Height)
  $directory = Split-Path -Parent $Path
  if (-not [string]::IsNullOrWhiteSpace($directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
  }
  $target.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $target.Dispose()
}

function New-CanvasRect {
  param(
    [int] $Width,
    [int] $Height,
    [bool] $Transparent = $false
  )

  $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  if ($Transparent) {
    $graphics.Clear([System.Drawing.Color]::Transparent)
  }
  return @{
    Bitmap = $bitmap
    Graphics = $graphics
  }
}

function Draw-IllustrationBackdrop {
  param(
    [System.Drawing.Graphics] $Graphics,
    [int] $Width,
    [int] $Height,
    [System.Drawing.Color] $Primary,
    [System.Drawing.Color] $Secondary
  )

  Draw-Glow -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new([float] ($Width * 0.04), [float] ($Height * 0.12), [float] ($Width * 0.44), [float] ($Height * 0.68))) -CenterColor $Primary
  Draw-Glow -Graphics $Graphics -Rect ([System.Drawing.RectangleF]::new([float] ($Width * 0.46), [float] ($Height * 0.08), [float] ($Width * 0.44), [float] ($Height * 0.68))) -CenterColor $Secondary

  $frameRect = [System.Drawing.RectangleF]::new([float] ($Width * 0.06), [float] ($Height * 0.10), [float] ($Width * 0.88), [float] ($Height * 0.76))
  $framePath = New-RoundedPath -Rect $frameRect -Radius 26
  $frameBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.PointF]::new([float] $frameRect.Left, [float] $frameRect.Top),
    [System.Drawing.PointF]::new([float] $frameRect.Right, [float] $frameRect.Bottom),
    [System.Drawing.Color]::FromArgb(50, 21, 16, 46),
    [System.Drawing.Color]::FromArgb(30, 12, 16, 34)
  )
  $Graphics.FillPath($frameBrush, $framePath)
  $frameBrush.Dispose()

  $framePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(68, 196, 186, 255)), 2.4
  $Graphics.DrawPath($framePen, $framePath)
  $framePen.Dispose()
  $framePath.Dispose()
}

function Draw-IllustrationBars {
  param(
    [System.Drawing.Graphics] $Graphics,
    [float] $StartX,
    [float] $BaselineY,
    [float[]] $Heights,
    [System.Drawing.Color] $Color
  )

  $brush = New-Object System.Drawing.SolidBrush $Color
  for ($index = 0; $index -lt $Heights.Length; $index++) {
    $height = $Heights[$index]
    $rect = [System.Drawing.RectangleF]::new([float] ($StartX + ($index * 15)), [float] ($BaselineY - $height), 9, [float] $height)
    $path = New-RoundedPath -Rect $rect -Radius 4
    $Graphics.FillPath($brush, $path)
    $path.Dispose()
  }
  $brush.Dispose()
}

function Draw-IllustrationCard {
  param(
    [System.Drawing.Graphics] $Graphics,
    [float] $X,
    [float] $Y,
    [float] $Width,
    [float] $Height,
    [System.Drawing.Color] $Color
  )

  $rect = [System.Drawing.RectangleF]::new($X, $Y, $Width, $Height)
  $path = New-RoundedPath -Rect $rect -Radius 18
  $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.PointF]::new([float] $rect.Left, [float] $rect.Top),
    [System.Drawing.PointF]::new([float] $rect.Right, [float] $rect.Bottom),
    [System.Drawing.Color]::FromArgb(80, $Color.R, $Color.G, $Color.B),
    [System.Drawing.Color]::FromArgb(18, 255, 255, 255)
  )
  $Graphics.FillPath($brush, $path)
  $brush.Dispose()
  $path.Dispose()
}

function Draw-IllustrationRing {
  param(
    [System.Drawing.Graphics] $Graphics,
    [float] $X,
    [float] $Y,
    [float] $Size,
    [System.Drawing.Color] $Color
  )

  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(120, $Color.R, $Color.G, $Color.B), 6)
  $Graphics.DrawEllipse($pen, $X, $Y, $Size, $Size)
  $pen.Dispose()
}

function Draw-IllustrationSilhouette {
  param(
    [System.Drawing.Graphics] $Graphics,
    [float] $CenterX,
    [float] $Top,
    [System.Drawing.Color] $Color
  )

  $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(86, $Color.R, $Color.G, $Color.B))
  $Graphics.FillEllipse($brush, $CenterX - 24, $Top, 48, 48)
  $bodyPath = New-RoundedPath -Rect ([System.Drawing.RectangleF]::new([float] ($CenterX - 42), [float] ($Top + 58), 84, 42)) -Radius 20
  $Graphics.FillPath($brush, $bodyPath)
  $bodyPath.Dispose()
  $brush.Dispose()
}

function Draw-EmptyVariant {
  param(
    [System.Drawing.Graphics] $Graphics,
    [int] $Width,
    [int] $Height,
    [string] $Variant
  )

  $purple = [System.Drawing.Color]::FromArgb(116, 123, 47, 190)
  $cyan = [System.Drawing.Color]::FromArgb(92, 34, 211, 238)
  $pink = [System.Drawing.Color]::FromArgb(92, 224, 64, 251)
  Draw-IllustrationBackdrop -Graphics $Graphics -Width $Width -Height $Height -Primary $purple -Secondary $cyan

  switch ($Variant) {
    'home' {
      Draw-IllustrationBars -Graphics $Graphics -StartX 62 -BaselineY 174 -Heights @(24, 42, 30, 54, 38, 26, 46, 28) -Color ([System.Drawing.Color]::FromArgb(80, 255, 255, 255))
      Draw-IllustrationCard -Graphics $Graphics -X 208 -Y 58 -Width 100 -Height 72 -Color $pink
    }
    'library' {
      Draw-IllustrationCard -Graphics $Graphics -X 58 -Y 54 -Width 98 -Height 72 -Color $purple
      Draw-IllustrationCard -Graphics $Graphics -X 108 -Y 74 -Width 112 -Height 80 -Color $cyan
      Draw-IllustrationCard -Graphics $Graphics -X 176 -Y 94 -Width 118 -Height 84 -Color $pink
    }
    'playlist' {
      Draw-IllustrationCard -Graphics $Graphics -X 66 -Y 68 -Width 74 -Height 74 -Color $purple
      Draw-IllustrationCard -Graphics $Graphics -X 146 -Y 50 -Width 74 -Height 74 -Color $pink
      Draw-IllustrationCard -Graphics $Graphics -X 226 -Y 68 -Width 74 -Height 74 -Color $cyan
    }
    'search' {
      Draw-IllustrationRing -Graphics $Graphics -X 96 -Y 62 -Size 84 -Color $cyan
      $handlePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(96, 224, 64, 251), 12)
      $handlePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
      $handlePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
      $Graphics.DrawLine($handlePen, 168, 134, 214, 178)
      $handlePen.Dispose()
      Draw-IllustrationBars -Graphics $Graphics -StartX 222 -BaselineY 176 -Heights @(16, 26, 20, 36, 28, 18) -Color ([System.Drawing.Color]::FromArgb(70, 255, 255, 255))
    }
    'player' {
      Draw-IllustrationCard -Graphics $Graphics -X 82 -Y 46 -Width 92 -Height 92 -Color $purple
      Draw-IllustrationBars -Graphics $Graphics -StartX 182 -BaselineY 174 -Heights @(30, 52, 34, 60, 42, 26, 48) -Color ([System.Drawing.Color]::FromArgb(84, 255, 255, 255))
    }
    'profile' {
      Draw-IllustrationSilhouette -Graphics $Graphics -CenterX 116 -Top 54 -Color $pink
      Draw-IllustrationCard -Graphics $Graphics -X 182 -Y 78 -Width 112 -Height 24 -Color $cyan
      Draw-IllustrationCard -Graphics $Graphics -X 182 -Y 114 -Width 88 -Height 20 -Color $purple
    }
    'subscription' {
      Draw-IllustrationCard -Graphics $Graphics -X 64 -Y 72 -Width 224 -Height 76 -Color $cyan
      Draw-IllustrationCard -Graphics $Graphics -X 90 -Y 92 -Width 56 -Height 34 -Color $pink
      Draw-IllustrationCard -Graphics $Graphics -X 164 -Y 92 -Width 86 -Height 20 -Color $purple
    }
    'payment' {
      Draw-IllustrationCard -Graphics $Graphics -X 68 -Y 70 -Width 210 -Height 84 -Color $purple
      Draw-IllustrationCard -Graphics $Graphics -X 96 -Y 98 -Width 32 -Height 24 -Color $cyan
      Draw-IllustrationCard -Graphics $Graphics -X 146 -Y 98 -Width 100 -Height 18 -Color $pink
    }
  }
}

$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$brandingDir = Join-Path $root 'assets/branding'
New-Item -ItemType Directory -Path $brandingDir -Force | Out-Null

$iconCanvas = New-Canvas -Size 1024
Draw-FullIcon -Graphics $iconCanvas.Graphics -Size 1024
$iconCanvas.Bitmap.Save((Join-Path $brandingDir 'shaya_app_icon_1024.png'), [System.Drawing.Imaging.ImageFormat]::Png)

$launchCanvas = New-Canvas -Size 1024 -Transparent $true
Draw-LaunchMark -Graphics $launchCanvas.Graphics -Size 1024
$launchCanvas.Bitmap.Save((Join-Path $brandingDir 'shaya_launch_mark_1024.png'), [System.Drawing.Imaging.ImageFormat]::Png)

$androidLegacyIcons = @(
  @{ Path = 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png'; Size = 48 },
  @{ Path = 'android/app/src/main/res/mipmap-hdpi/ic_launcher.png'; Size = 72 },
  @{ Path = 'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png'; Size = 96 },
  @{ Path = 'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png'; Size = 144 },
  @{ Path = 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'; Size = 192 }
)

foreach ($item in $androidLegacyIcons) {
  Save-ScaledPng -Source $iconCanvas.Bitmap -Width $item.Size -Height $item.Size -Path (Join-Path $root $item.Path)
}

Save-ScaledPng -Source $launchCanvas.Bitmap -Width 240 -Height 240 -Path (Join-Path $root 'android/app/src/main/res/drawable/launch_mark.png')
Save-ScaledPng -Source $launchCanvas.Bitmap -Width 432 -Height 432 -Path (Join-Path $root 'android/app/src/main/res/drawable-nodpi/ic_launcher_foreground_art.png')

$appIconFiles = Get-ChildItem (Join-Path $root 'ios/Runner/Assets.xcassets/AppIcon.appiconset') -Filter '*.png'
foreach ($file in $appIconFiles) {
  $current = [System.Drawing.Image]::FromFile($file.FullName)
  $width = $current.Width
  $height = $current.Height
  $current.Dispose()
  Save-ScaledPng -Source $iconCanvas.Bitmap -Width $width -Height $height -Path $file.FullName
}

$launchImageTargets = @(
  @{ Path = 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png'; Size = 180 },
  @{ Path = 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png'; Size = 360 },
  @{ Path = 'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png'; Size = 540 }
)

foreach ($target in $launchImageTargets) {
  Save-ScaledPng -Source $launchCanvas.Bitmap -Width $target.Size -Height $target.Size -Path (Join-Path $root $target.Path)
}

$emptyVariants = @(
  'home',
  'library',
  'playlist',
  'search',
  'player',
  'profile',
  'subscription',
  'payment'
)

foreach ($variant in $emptyVariants) {
  $variantCanvas = New-CanvasRect -Width 360 -Height 224 -Transparent $true
  Draw-EmptyVariant -Graphics $variantCanvas.Graphics -Width 360 -Height 224 -Variant $variant
  $variantCanvas.Bitmap.Save((Join-Path $brandingDir "empty_$variant.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $variantCanvas.Graphics.Dispose()
  $variantCanvas.Bitmap.Dispose()
}

$iconCanvas.Graphics.Dispose()
$iconCanvas.Bitmap.Dispose()
$launchCanvas.Graphics.Dispose()
$launchCanvas.Bitmap.Dispose()

Write-Output 'Brand assets generated successfully.'
