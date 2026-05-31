# Generates 1024x500 Play Store feature graphics (24-bit PNG, no alpha) for each flavor.
Add-Type -AssemblyName System.Drawing

$Root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function C([int]$r,[int]$g,[int]$b){ [System.Drawing.Color]::FromArgb(255,$r,$g,$b) }
function Darken([System.Drawing.Color]$c,[double]$f){ C ([int]($c.R*$f)) ([int]($c.G*$f)) ([int]($c.B*$f)) }
function Lighten([System.Drawing.Color]$c,[double]$f){ C ([int]([Math]::Min(255,$c.R+(255-$c.R)*$f))) ([int]([Math]::Min(255,$c.G+(255-$c.G)*$f))) ([int]([Math]::Min(255,$c.B+(255-$c.B)*$f))) }
function Font([single]$sz,[int]$style=0){ New-Object System.Drawing.Font('Segoe UI',$sz,[System.Drawing.FontStyle]$style,[System.Drawing.GraphicsUnit]::Pixel) }
function RoundPath([single]$x,[single]$y,[single]$w,[single]$h,[single]$r){
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath; $d=$r*2
  $p.AddArc($x,$y,$d,$d,180,90); $p.AddArc($x+$w-$d,$y,$d,$d,270,90)
  $p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90); $p.AddArc($x,$y+$h-$d,$d,$d,90,90)
  $p.CloseFigure(); return $p
}
function FillRound($g,$col,$x,$y,$w,$h,$r){ $p=RoundPath $x $y $w $h $r; $b=New-Object System.Drawing.SolidBrush($col); $g.FillPath($b,$p); $b.Dispose(); $p.Dispose() }
function Text($g,$s,$font,$col,[single]$x,[single]$y){ $b=New-Object System.Drawing.SolidBrush($col); $g.DrawString($s,$font,$b,$x,$y); $b.Dispose() }
function TextC($g,$s,$font,$col,[single]$cx,[single]$y){ $sz=$g.MeasureString($s,$font); $b=New-Object System.Drawing.SolidBrush($col); $g.DrawString($s,$font,$b,($cx-$sz.Width/2),$y); $b.Dispose() }

function Make($flavor,$name,$primary,$letter){
  $fw=1024; $fh=500
  $dk = Darken $primary 0.78
  $accent = Lighten $primary 0.22
  $soft = C 219 234 254  # near-white tint for subtitle, works on all
  $bmp = New-Object System.Drawing.Bitmap($fw,$fh,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode='AntiAlias'; $g.TextRenderingHint='ClearTypeGridFit'; $g.InterpolationMode='HighQualityBicubic'
  # gradient bg
  $rect = New-Object System.Drawing.Rectangle(0,0,$fw,$fh)
  $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect,$primary,$dk,90)
  $g.FillRectangle($br,$rect); $br.Dispose()
  # decorative circles
  $bru = New-Object System.Drawing.SolidBrush($accent)
  $g.FillEllipse($bru,720,-120,420,420); $g.FillEllipse($bru,860,300,300,300); $bru.Dispose()
  # logo badge
  FillRound $g ([System.Drawing.Color]::White) 80 175 150 150 36
  TextC $g $letter (Font 100 1) $primary 155 188
  # wordmark + tagline
  Text $g $name (Font 64 1) ([System.Drawing.Color]::White) 270 175
  Text $g 'Fees, attendance, results & notices' (Font 36 0) $soft 272 265
  Text $g 'all in one app' (Font 36 0) $soft 272 312
  # output
  $outDir = Join-Path $Root "screenshots\$flavor"
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
  $path = Join-Path $outDir 'feature_graphic_1024x500.png'
  $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Write-Host "  $flavor -> $path"
}

Make 'jmukhisics'   'JMukhisics'      (C 30 64 175)  'J'
Make 'sicschool'    'SIC School'      (C 22 101 52)  'S'
Make 'schoolfeepro' 'School Fee Pro'  (C 124 58 237) ([char]0x20B9)
Make 'theshivalik'  'The Shivalik'    (C 239 68 68)  'S'

Write-Host "`nDone."
