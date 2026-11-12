# ホーム画面アイコン（icon-180.png / icon-512.png）を生成するスクリプト。
# デザインを変えたいときはここを編集して、リポジトリ直下で次を実行する:
#   powershell -ExecutionPolicy Bypass -File tools/make-icons.ps1
# Windows 標準の System.Drawing だけを使うので、追加のインストールは要らない。

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$S = 1024   # 最初は大きく描いて、あとで縮小する（きれいに見せるため）

function New-Color($a, $r, $g, $b) { [System.Drawing.Color]::FromArgb($a, $r, $g, $b) }

$bmp = New-Object System.Drawing.Bitmap $S, $S
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.PixelOffsetMode = 'HighQuality'

# --- 背景：深さで変わる青のグラデーション（iOS が角を丸めるので、全面を塗る） ---
$rect = New-Object System.Drawing.Rectangle 0, 0, $S, $S
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, (New-Color 255 60 175 215), (New-Color 255 4 20 52), 90
$blend = New-Object System.Drawing.Drawing2D.ColorBlend 4
$blend.Colors = @((New-Color 255 70 185 220), (New-Color 255 22 108 170), (New-Color 255 8 52 108), (New-Color 255 3 18 46))
$blend.Positions = @(0.0, 0.35, 0.72, 1.0)
$bg.InterpolationColors = $blend
$g.FillRectangle($bg, $rect)

# --- 上から差す光の筋 ---
foreach ($ray in @(@(250, 130, 70), @(470, 190, 50), @(700, 120, 60))) {
  $x = $ray[0]; $w = $ray[1]; $a = $ray[2]
  $pts = @(
    (New-Object System.Drawing.PointF ($x - $w / 4), 0),
    (New-Object System.Drawing.PointF ($x + $w / 4), 0),
    (New-Object System.Drawing.PointF ($x + $w + 110), ($S * 1.1)),
    (New-Object System.Drawing.PointF ($x - $w + 110), ($S * 1.1))
  )
  $rb = New-Object System.Drawing.SolidBrush (New-Color $a 220 245 255)
  $g.FillPolygon($rb, $pts)
}

# --- 泡 ---
foreach ($b in @(@(760, 700, 38), @(820, 560, 24), @(730, 470, 16), @(250, 760, 26), @(300, 640, 14))) {
  $pen = New-Object System.Drawing.Pen (New-Color 190 230 250 255), 7
  $g.DrawEllipse($pen, ($b[0] - $b[2]), ($b[1] - $b[2]), ($b[2] * 2), ($b[2] * 2))
  $hl = New-Object System.Drawing.SolidBrush (New-Color 200 255 255 255)
  $g.FillEllipse($hl, ($b[0] - $b[2] * 0.45), ($b[1] - $b[2] * 0.55), ($b[2] * 0.35), ($b[2] * 0.35))
}

# --- 魚（中心 512,512、右向き） ---
$g.TranslateTransform(500, 520)
$g.RotateTransform(-8)

# 尾びれ
$tail = [System.Drawing.Drawing2D.GraphicsPath]::new()
$tail.AddBezier(-150, 0, -230, -40, -290, -110, -330, -150)
$tail.AddBezier(-330, -150, -300, -60, -300, 60, -330, 150)
$tail.AddBezier(-330, 150, -290, 110, -230, 40, -150, 0)
$g.FillPath((New-Object System.Drawing.SolidBrush (New-Color 255 255 140 70)), $tail)

# 体
$body = [System.Drawing.Drawing2D.GraphicsPath]::new()
$body.AddBezier(260, 0, 200, -170, -20, -230, -200, -40)
$body.AddLine(-200, -40, -200, 40)
$body.AddBezier(-200, 40, -20, 230, 200, 170, 260, 0)
$bodyRect = New-Object System.Drawing.RectangleF -210, -230, 480, 460
$bodyBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $bodyRect, (New-Color 255 255 175 95), (New-Color 255 255 105 55), 90
$g.FillPath($bodyBrush, $body)

# 腹の明るい部分
$belly = [System.Drawing.Drawing2D.GraphicsPath]::new()
$belly.AddBezier(230, 20, 150, 120, 0, 170, -140, 60)
$belly.AddBezier(-140, 60, 0, 90, 150, 80, 230, 20)
$g.FillPath((New-Object System.Drawing.SolidBrush (New-Color 120 255 235 200)), $belly)

# 背びれ
$fin = [System.Drawing.Drawing2D.GraphicsPath]::new()
$fin.AddBezier(60, -170, 10, -260, -70, -270, -110, -190)
$fin.AddBezier(-110, -190, -50, -200, 10, -190, 60, -170)
$g.FillPath((New-Object System.Drawing.SolidBrush (New-Color 255 255 120 62)), $fin)

# 目
$g.FillEllipse((New-Object System.Drawing.SolidBrush (New-Color 255 255 255 255)), 150, -70, 62, 62)
$g.FillEllipse((New-Object System.Drawing.SolidBrush (New-Color 255 15 35 70)), 168, -56, 34, 34)
$g.ResetTransform()

$g.Dispose()

# --- 縮小して保存 ---
function Save-Resized($src, $size, $path) {
  $out = New-Object System.Drawing.Bitmap $size, $size
  $gg = [System.Drawing.Graphics]::FromImage($out)
  $gg.InterpolationMode = 'HighQualityBicubic'
  $gg.SmoothingMode = 'HighQuality'
  $gg.PixelOffsetMode = 'HighQuality'
  $gg.DrawImage($src, 0, 0, $size, $size)
  $gg.Dispose()
  $out.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $out.Dispose()
}
Save-Resized $bmp 180 (Join-Path $root 'icon-180.png')
Save-Resized $bmp 512 (Join-Path $root 'icon-512.png')
$bmp.Dispose()
Write-Host 'icon-180.png and icon-512.png created'
