# Generates the 5 phone screenshots (1080x1920, 24-bit PNG, no alpha) for every flavor,
# branded with each app's name, primary colour and logo mark.
Add-Type -AssemblyName System.Drawing

$Root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function C([int]$r,[int]$g,[int]$b){ [System.Drawing.Color]::FromArgb(255,$r,$g,$b) }
function Darken([System.Drawing.Color]$c,[double]$f){ C ([int]($c.R*$f)) ([int]($c.G*$f)) ([int]($c.B*$f)) }
function Lighten([System.Drawing.Color]$c,[double]$f){ C ([int]([Math]::Min(255,$c.R+(255-$c.R)*$f))) ([int]([Math]::Min(255,$c.G+(255-$c.G)*$f))) ([int]([Math]::Min(255,$c.B+(255-$c.B)*$f))) }
function Font([single]$sz,[int]$style=0){ New-Object System.Drawing.Font('Segoe UI',$sz,[System.Drawing.FontStyle]$style,[System.Drawing.GraphicsUnit]::Pixel) }

$white=C 255 255 255; $bg=C 245 247 250; $ink=C 17 24 39; $sub=C 107 114 128
$green=C 16 185 129; $red=C 239 68 68; $amber=C 245 158 11; $line=C 229 231 235

function RoundPath([single]$x,[single]$y,[single]$w,[single]$h,[single]$r){
  $p=New-Object System.Drawing.Drawing2D.GraphicsPath; $d=$r*2
  $p.AddArc($x,$y,$d,$d,180,90); $p.AddArc($x+$w-$d,$y,$d,$d,270,90)
  $p.AddArc($x+$w-$d,$y+$h-$d,$d,$d,0,90); $p.AddArc($x,$y+$h-$d,$d,$d,90,90)
  $p.CloseFigure(); return $p
}
function FillRound($g,$col,$x,$y,$w,$h,$r){
  $b=New-Object System.Drawing.SolidBrush($col)
  if($r -le 0){ $g.FillRectangle($b,[single]$x,[single]$y,[single]$w,[single]$h) }
  else { $p=RoundPath $x $y $w $h $r; $g.FillPath($b,$p); $p.Dispose() }
  $b.Dispose()
}
function VGrad($g,$c1,$c2,$x,$y,$w,$h){ $r=New-Object System.Drawing.Rectangle($x,$y,$w,$h); $br=New-Object System.Drawing.Drawing2D.LinearGradientBrush($r,$c1,$c2,90); $g.FillRectangle($br,$r); $br.Dispose() }
function Text($g,$s,$font,$col,[single]$x,[single]$y){ $b=New-Object System.Drawing.SolidBrush($col); $g.DrawString($s,$font,$b,$x,$y); $b.Dispose() }
function TextC($g,$s,$font,$col,[single]$cx,[single]$y){ $sz=$g.MeasureString($s,$font); $b=New-Object System.Drawing.SolidBrush($col); $g.DrawString($s,$font,$b,($cx-$sz.Width/2),$y); $b.Dispose() }
function NewG([int]$w,[int]$h,[System.Drawing.Color]$fill){
  $bmp=New-Object System.Drawing.Bitmap($w,$h,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $g=[System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode='AntiAlias'; $g.TextRenderingHint='ClearTypeGridFit'; $g.InterpolationMode='HighQualityBicubic'
  $g.Clear($fill); return @($bmp,$g)
}

$W=1080; $H=1920; $RUPEE=[char]0x20B9

function Chrome($g,$primary,$primaryDk,$caption,$title,$active){
  VGrad $g $primary $primaryDk 0 0 $W 360
  TextC $g $caption (Font 60 1) $white ($W/2) 150
  Text $g $title (Font 46 1) $white 56 270
  $navY=$H-170; FillRound $g $white 0 $navY $W 170 0
  $g.DrawLine((New-Object System.Drawing.Pen($line,2)),0,$navY,$W,$navY)
  $tabs=@('Dashboard','Fees','Results','Profile')
  for($i=0;$i -lt 4;$i++){ $cx=($W/8)*(2*$i+1); $col= if($i -eq $active){$primary}else{$sub}; FillRound $g $col ($cx-26) ($navY+38) 52 52 14; TextC $g $tabs[$i] (Font 26 0) $col $cx ($navY+104) }
}

function Build($flavor,$name,$primary,$letter){
  $primaryDk = Darken $primary 0.78
  $tint = Lighten $primary 0.82
  $tintBadge = Lighten $primary 0.86
  $outDir = Join-Path $Root "screenshots\$flavor"
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
  function SaveBmp($bmp,$n){ $bmp.Save((Join-Path $outDir $n),[System.Drawing.Imaging.ImageFormat]::Png) }

  # 1 welcome
  $c=NewG $W $H $bg; $b=$c[0]; $g=$c[1]
  VGrad $g $primary $primaryDk 0 0 $W $H
  FillRound $g $white 440 520 200 200 48
  TextC $g $letter (Font 130 1) $primary ($W/2) 545
  TextC $g $name (Font 70 1) $white ($W/2) 780
  TextC $g 'Your whole school, in one app' (Font 40 0) (Lighten $primary 0.7) ($W/2) 880
  $py=1080; foreach($p in @('Fees','Attendance','Results','Notices','Transport')){ $pw=($g.MeasureString($p,(Font 34 0))).Width+60; FillRound $g (Lighten $primary 0.18) (($W-$pw)/2) $py $pw 76 38; TextC $g $p (Font 34 0) $white ($W/2) ($py+18); $py+=100 }
  TextC $g 'Sign in with your school account' (Font 32 0) (Lighten $primary 0.6) ($W/2) 1700
  SaveBmp $b '01_welcome.png'; $g.Dispose(); $b.Dispose()

  # 2 fees
  $c=NewG $W $H $bg; $b=$c[0]; $g=$c[1]
  Chrome $g $primary $primaryDk 'Pay fees in seconds' 'Dashboard' 1
  $y=420; FillRound $g $white 56 $y 968 320 28
  Text $g 'Total Fee Due' (Font 34 0) $sub 100 ($y+44)
  Text $g ("$RUPEE`12,500") (Font 88 1) $ink 100 ($y+90)
  FillRound $g $primary 100 ($y+220) 360 84 22; TextC $g 'Pay Now' (Font 38 1) $white 280 ($y+240)
  FillRound $g $bg 500 ($y+220) 230 84 22; TextC $g 'View Plan' (Font 34 0) $primary 615 ($y+240)
  $y+=380; Text $g 'Recent Receipts' (Font 40 1) $ink 56 $y; $y+=80
  foreach($r in @(@('Term 2 Tuition','15 Apr 2026','8,000'),@('Transport - Q1','02 Apr 2026','3,200'),@('Annual Charges','10 Mar 2026','5,500'))){
    FillRound $g $white 56 $y 968 150 24; FillRound $g $tintBadge 84 ($y+34) 84 84 20; TextC $g $RUPEE (Font 44 1) $primary 126 ($y+50)
    Text $g $r[0] (Font 38 1) $ink 200 ($y+34); Text $g $r[1] (Font 30 0) $sub 200 ($y+86)
    Text $g ("$RUPEE$($r[2])") (Font 40 1) $green 760 ($y+50); $y+=174 }
  SaveBmp $b '02_fees.png'; $g.Dispose(); $b.Dispose()

  # 3 attendance
  $c=NewG $W $H $bg; $b=$c[0]; $g=$c[1]
  Chrome $g $primary $primaryDk 'Track daily attendance' 'Attendance' 0
  $y=440; $cx=$W/2; $cy=$y+180; $rad=170
  $g.DrawEllipse((New-Object System.Drawing.Pen($line,40)),($cx-$rad),($cy-$rad),($rad*2),($rad*2))
  $pen2=New-Object System.Drawing.Pen($green,40); $pen2.StartCap='Round'; $pen2.EndCap='Round'; $g.DrawArc($pen2,($cx-$rad),($cy-$rad),($rad*2),($rad*2),-90,331)
  TextC $g '92%' (Font 96 1) $ink $cx ($cy-70); TextC $g 'Present' (Font 36 0) $sub $cx ($cy+40)
  $y=$cy+$rad+70
  foreach($s in @(@('Present','184',$green),@('Absent','9',$red),@('Late','7',$amber))){
    FillRound $g $white 56 $y 968 130 22; FillRound $g $s[2] 100 ($y+38) 54 54 14
    Text $g $s[0] (Font 40 1) $ink 190 ($y+40); Text $g ($s[1]+' days') (Font 36 0) $sub 760 ($y+44); $y+=154 }
  SaveBmp $b '03_attendance.png'; $g.Dispose(); $b.Dispose()

  # 4 results
  $c=NewG $W $H $bg; $b=$c[0]; $g=$c[1]
  Chrome $g $primary $primaryDk 'Exam results & report cards' 'Results' 2
  $y=420; FillRound $g $white 56 $y 968 200 28
  Text $g 'Term 1 - Overall' (Font 34 0) $sub 100 ($y+40); Text $g '88.6%' (Font 84 1) $ink 100 ($y+86)
  FillRound $g (C 220 252 231) 720 ($y+60) 220 90 24; TextC $g 'Grade A' (Font 44 1) (C 5 150 105) 830 ($y+78)
  $y+=260
  foreach($s in @(@('English','92',$green),@('Mathematics','85',$green),@('Science','78',$green),@('Social Studies','69',$amber),@('Hindi','95',$green))){
    FillRound $g $white 56 $y 968 130 24; Text $g $s[0] (Font 40 1) $ink 100 ($y+26)
    FillRound $g $bg 100 ($y+84) 600 22 11; $barw=[int](600*([int]$s[1]/100.0)); FillRound $g $s[2] 100 ($y+84) $barw 22 11
    Text $g ($s[1]+'/100') (Font 38 1) $ink 800 ($y+44); $y+=154 }
  SaveBmp $b '04_results.png'; $g.Dispose(); $b.Dispose()

  # 5 calendar
  $c=NewG $W $H $bg; $b=$c[0]; $g=$c[1]
  Chrome $g $primary $primaryDk 'Never miss a notice' 'Calendar' 0
  $y=430
  foreach($e in @(@('05','Jun','Annual Day Rehearsal','School Auditorium - 9:00 AM',$primary),@('08','Jun','PTM - Class 5 to 8','Respective Classrooms',$amber),@('12','Jun','Science Exhibition','Main Hall - 10:30 AM',$green),@('18','Jun','Summer Break Begins','Holiday',$red))){
    FillRound $g $white 56 $y 968 180 24; FillRound $g $e[4] 84 ($y+30) 120 120 22
    TextC $g $e[0] (Font 54 1) $white 144 ($y+46); TextC $g $e[1] (Font 28 0) $white 144 ($y+108)
    Text $g $e[2] (Font 40 1) $ink 240 ($y+36); Text $g $e[3] (Font 30 0) $sub 240 ($y+96); $y+=204 }
  SaveBmp $b '05_calendar.png'; $g.Dispose(); $b.Dispose()

  Write-Host "  $flavor : 5 screenshots written to $outDir"
}

Build 'jmukhisics'   'JMukhisics'      (C 30 64 175)  'J'
Build 'sicschool'    'SIC School'      (C 22 101 52)  'S'
Build 'schoolfeepro' 'School Fee Pro'  (C 124 58 237) $RUPEE
Build 'theshivalik'  'The Shivalik'    (C 239 68 68)  'S'

Write-Host "`nDone."
