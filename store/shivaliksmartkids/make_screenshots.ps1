# Generates Play Store marketing graphics for Shivalik Smart Kids.
# Output: 24-bit PNG (no alpha). 5 phone screenshots (1080x1920) + feature graphic (1024x500).
Add-Type -AssemblyName System.Drawing

$OutDir = Join-Path $PSScriptRoot '..\..\screenshots\shivaliksmartkids'
$OutDir = [System.IO.Path]::GetFullPath($OutDir)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# ── Palette ──────────────────────────────────────────────────────────────────
function C([int]$r,[int]$g,[int]$b){ [System.Drawing.Color]::FromArgb(255,$r,$g,$b) }
$primary    = C 37 99 235
$primaryDk  = C 29 78 216
$bg         = C 245 247 250
$white      = C 255 255 255
$ink        = C 17 24 39
$sub        = C 107 114 128
$green      = C 16 185 129
$red        = C 239 68 68
$amber      = C 245 158 11
$line       = C 229 231 235

# ── Helpers ──────────────────────────────────────────────────────────────────
function New-Canvas([int]$w,[int]$h,[System.Drawing.Color]$fill){
  $bmp = New-Object System.Drawing.Bitmap($w,$h,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.Clear($fill)
  return @($bmp,$g)
}
function RoundPath([single]$x,[single]$y,[single]$w,[single]$h,[single]$r){
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $r*2
  $p.AddArc($x,$y,$d,$d,180,90)
  $p.AddArc($x+$w-$d,$y,$d,$d,270,90)
  $p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90)
  $p.AddArc($x,$y+$h-$d,$d,$d,90,90)
  $p.CloseFigure()
  return $p
}
function FillRound($g,$col,$x,$y,$w,$h,$r){
  $b = New-Object System.Drawing.SolidBrush($col)
  if($r -le 0){
    $g.FillRectangle($b,[single]$x,[single]$y,[single]$w,[single]$h)
  } else {
    $p = RoundPath $x $y $w $h $r
    $g.FillPath($b,$p); $p.Dispose()
  }
  $b.Dispose()
}
function VGradient($g,$col1,$col2,$x,$y,$w,$h){
  $rect = New-Object System.Drawing.Rectangle($x,$y,$w,$h)
  $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect,$col1,$col2,90)
  $g.FillRectangle($br,$rect); $br.Dispose()
}
function Font([single]$sz,[int]$style=0){ New-Object System.Drawing.Font('Segoe UI',$sz,[System.Drawing.FontStyle]$style,[System.Drawing.GraphicsUnit]::Pixel) }
function Text($g,$s,$font,$col,[single]$x,[single]$y){
  $b = New-Object System.Drawing.SolidBrush($col); $g.DrawString($s,$font,$b,$x,$y); $b.Dispose()
}
function TextC($g,$s,$font,$col,[single]$cx,[single]$y){
  $sf = New-Object System.Drawing.StringFormat; $sf.Alignment=[System.Drawing.StringFormat]::GenericTypographic.Alignment
  $sz = $g.MeasureString($s,$font); $b = New-Object System.Drawing.SolidBrush($col)
  $g.DrawString($s,$font,$b,($cx-$sz.Width/2),$y); $b.Dispose()
}
function Save($bmp,$name){
  $path = Join-Path $OutDir $name
  $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)
  Write-Host "  saved $name  ($($bmp.Width)x$($bmp.Height))"
}

$W=1080; $H=1920

# Common chrome: caption band + app bar + bottom nav. Returns nothing.
function Chrome($g,$caption,$appbarTitle,$activeTab){
  # status + caption band
  VGradient $g $primary $primaryDk 0 0 $W 360
  $hl = Font 60 1
  TextC $g $caption $hl $white ($W/2) 150
  # app bar title strip
  $tf = Font 46 1
  Text $g $appbarTitle $tf $white 56 270
  # bottom nav
  $navY = $H-170
  FillRound $g $white 0 ($navY) $W 170 0
  $g.DrawLine((New-Object System.Drawing.Pen($line,2)),0,$navY,$W,$navY)
  $tabs = @('Dashboard','Fees','Results','Profile')
  $nf = Font 26 0
  for($i=0;$i -lt 4;$i++){
    $cx = ($W/8)*(2*$i+1)
    $col = if($i -eq $activeTab){ $primary } else { $sub }
    FillRound $g $col ($cx-26) ($navY+38) 52 52 14
    TextC $g $tabs[$i] $nf $col $cx ($navY+104)
  }
}

# ── 1. Welcome / hero ────────────────────────────────────────────────────────
$c = New-Canvas $W $H $bg; $bmp=$c[0]; $g=$c[1]
VGradient $g $primary $primaryDk 0 0 $W $H
# logo badge
FillRound $g $white 440 520 200 200 48
TextC $g 'S' (Font 130 1) $primary ($W/2) 545
TextC $g 'Shivalik Smart Kids' (Font 70 1) $white ($W/2) 780
TextC $g 'Your whole school, in one app' (Font 40 0) (C 219 234 254) ($W/2) 880
# feature pills
$pills = @('Fees','Attendance','Results','Notices','Transport')
$pf = Font 34 0; $py=1080
foreach($p in $pills){
  $pw = ($g.MeasureString($p,$pf)).Width + 60
  FillRound $g (C 59 130 246) (($W-$pw)/2) $py $pw 76 38
  TextC $g $p $pf $white ($W/2) ($py+18)
  $py += 100
}
TextC $g 'Sign in with your school account' (Font 32 0) (C 191 219 254) ($W/2) 1700
Save $bmp '01_welcome.png'; $g.Dispose(); $bmp.Dispose()

# ── 2. Dashboard / Fees ──────────────────────────────────────────────────────
$c = New-Canvas $W $H $bg; $bmp=$c[0]; $g=$c[1]
Chrome $g 'Pay fees in seconds' 'Dashboard' 1
$y=420
# Fee due card
FillRound $g $white 56 $y 968 320 28
Text $g 'Total Fee Due' (Font 34 0) $sub 100 ($y+44)
Text $g ("$([char]0x20B9)12,500") (Font 88 1) $ink 100 ($y+90)
FillRound $g $primary 100 ($y+220) 360 84 22
TextC $g 'Pay Now' (Font 38 1) $white 280 ($y+240)
FillRound $g $bg 500 ($y+220) 230 84 22
TextC $g 'View Plan' (Font 34 0) $primary 615 ($y+240)
$y += 380
# Receipts list
Text $g 'Recent Receipts' (Font 40 1) $ink 56 $y; $y+=80
foreach($r in @(@('Term 2 Tuition','15 Apr 2026','8,000'),@('Transport - Q1','02 Apr 2026','3,200'),@('Annual Charges','10 Mar 2026','5,500'))){
  FillRound $g $white 56 $y 968 150 24
  FillRound $g (C 219 234 254) 84 ($y+34) 84 84 20
  TextC $g ([char]0x20B9) (Font 44 1) $primary 126 ($y+50)
  Text $g $r[0] (Font 38 1) $ink 200 ($y+34)
  Text $g $r[1] (Font 30 0) $sub 200 ($y+86)
  Text $g ([char]0x20B9 + $r[2]) (Font 40 1) $green 760 ($y+50)
  $y += 174
}
Save $bmp '02_fees.png'; $g.Dispose(); $bmp.Dispose()

# ── 3. Attendance ────────────────────────────────────────────────────────────
$c = New-Canvas $W $H $bg; $bmp=$c[0]; $g=$c[1]
Chrome $g 'Track daily attendance' 'Attendance' 0
$y=440
# percentage ring
$cx=$W/2; $cy=$y+180; $rad=170
$pen=New-Object System.Drawing.Pen($line,40); $g.DrawEllipse($pen,($cx-$rad),($cy-$rad),($rad*2),($rad*2))
$pen2=New-Object System.Drawing.Pen($green,40); $pen2.StartCap='Round'; $pen2.EndCap='Round'
$g.DrawArc($pen2,($cx-$rad),($cy-$rad),($rad*2),($rad*2),-90,331)
TextC $g '92%' (Font 96 1) $ink $cx ($cy-70)
TextC $g 'Present' (Font 36 0) $sub $cx ($cy+40)
$y=$cy+$rad+70
# month chips legend
foreach($s in @(@('Present','184',$green),@('Absent','9',$red),@('Late','7',$amber))){
  FillRound $g $white 56 $y 968 130 22
  FillRound $g $s[2] 100 ($y+38) 54 54 14
  Text $g $s[0] (Font 40 1) $ink 190 ($y+40)
  Text $g ($s[1] + ' days') (Font 36 0) $sub 760 ($y+44)
  $y+=154
}
Save $bmp '03_attendance.png'; $g.Dispose(); $bmp.Dispose()

# ── 4. Results ───────────────────────────────────────────────────────────────
$c = New-Canvas $W $H $bg; $bmp=$c[0]; $g=$c[1]
Chrome $g 'Exam results & report cards' 'Results' 2
$y=420
FillRound $g $white 56 $y 968 200 28
Text $g 'Term 1 - Overall' (Font 34 0) $sub 100 ($y+40)
Text $g '88.6%' (Font 84 1) $ink 100 ($y+86)
FillRound $g (C 220 252 231) 720 ($y+60) 220 90 24
TextC $g 'Grade A' (Font 44 1) (C 5 150 105) 830 ($y+78)
$y+=260
foreach($s in @(@('English','92',$green),@('Mathematics','85',$green),@('Science','78',$green),@('Social Studies','69',$amber),@('Hindi','95',$green))){
  FillRound $g $white 56 $y 968 130 24
  Text $g $s[0] (Font 40 1) $ink 100 ($y+26)
  # bar
  FillRound $g $bg 100 ($y+84) 600 22 11
  $barw=[int](600*([int]$s[1]/100.0))
  FillRound $g $s[2] 100 ($y+84) $barw 22 11
  Text $g ($s[1] + '/100') (Font 38 1) $ink 800 ($y+44)
  $y+=154
}
Save $bmp '04_results.png'; $g.Dispose(); $bmp.Dispose()

# ── 5. Calendar / Notices ────────────────────────────────────────────────────
$c = New-Canvas $W $H $bg; $bmp=$c[0]; $g=$c[1]
Chrome $g 'Never miss a notice' 'Calendar' 0
$y=430
foreach($e in @(@('05','Jun','Annual Day Rehearsal','School Auditorium - 9:00 AM',$primary),@('08','Jun','PTM - Class 5 to 8','Respective Classrooms',$amber),@('12','Jun','Science Exhibition','Main Hall - 10:30 AM',$green),@('18','Jun','Summer Break Begins','Holiday',$red))){
  FillRound $g $white 56 $y 968 180 24
  FillRound $g $e[4] 84 ($y+30) 120 120 22
  TextC $g $e[0] (Font 54 1) $white 144 ($y+46)
  TextC $g $e[1] (Font 28 0) $white 144 ($y+108)
  Text $g $e[2] (Font 40 1) $ink 240 ($y+36)
  Text $g $e[3] (Font 30 0) $sub 240 ($y+96)
  $y+=204
}
Save $bmp '05_calendar.png'; $g.Dispose(); $bmp.Dispose()

# ── Feature graphic 1024x500 ─────────────────────────────────────────────────
$fw=1024; $fh=500
$c = New-Canvas $fw $fh $primary; $bmp=$c[0]; $g=$c[1]
VGradient $g $primary $primaryDk 0 0 $fw $fh
# decorative circles
$bru=New-Object System.Drawing.SolidBrush((C 59 130 246))
$g.FillEllipse($bru,720,-120,420,420); $g.FillEllipse($bru,860,300,300,300); $bru.Dispose()
# logo badge
FillRound $g $white 80 175 150 150 36
TextC $g 'S' (Font 100 1) $primary 155 190
Text $g 'Shivalik Smart Kids' (Font 64 1) $white 270 175
Text $g 'Fees, attendance, results & notices' (Font 36 0) (C 219 234 254) 272 265
Text $g 'all in one app' (Font 36 0) (C 219 234 254) 272 312
Save $bmp 'feature_graphic_1024x500.png'; $g.Dispose(); $bmp.Dispose()

Write-Host "`nAll graphics written to $OutDir"
