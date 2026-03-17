# HushFlow - Compact breathing animation for Windows
# PowerShell version with ANSI color support (Windows 10+)

$MarkerFile = "$env:TEMP\hushflow-working"
$ConfigDir = "$env:USERPROFILE\.claude\hushflow"
$ConfigFile = "$ConfigDir\config"

# Theme colors (RGB)
$theme = "teal"
if (Test-Path $ConfigFile) {
    $line = Get-Content $ConfigFile | Where-Object { $_ -match "^theme=" }
    if ($line) { $theme = ($line -split "=")[1] }
}

switch ($theme) {
    "twilight" { $CB = "209;196;233"; $CD = "126;87;194"; $CDim = "158;158;158" }
    "amber"    { $CB = "255;224;178"; $CD = "245;124;0";  $CDim = "161;136;127" }
    default    { $CB = "128;203;196"; $CD = "0;121;107";  $CDim = "120;144;156" }
}

$ColorIn  = "`e[38;2;${CB}m"
$ColorOut = "`e[38;2;${CD}m"
$Dim      = "`e[38;2;${CDim}m"
$Reset    = "`e[0m"

# Exercises: name, inhale, hold1, exhale, hold2, type
$Exercises = @(
    @{ Name="Coherent"; In=5.5; H1=0; Ex=5.5; H2=0; Type="standard" },
    @{ Name="Sigh"; In=4; H1=1; Ex=10; H2=0; Type="double_inhale" },
    @{ Name="Box"; In=4; H1=4; Ex=4; H2=4; Type="standard" },
    @{ Name="4-7-8"; In=4; H1=7; Ex=8; H2=0; Type="standard" }
)

$currentExercise = 0
if (Test-Path $ConfigFile) {
    $line = Get-Content $ConfigFile | Where-Object { $_ -match "^exercise=" }
    if ($line) {
        $val = [int](($line -split "=")[1])
        if ($val -ge 0 -and $val -lt $Exercises.Count) { $currentExercise = $val }
    }
}

$ex = $Exercises[$currentExercise]
$TickRate = 10

function SecToTicks($s) { [math]::Round($s * $TickRate) }
function Ease($x) { [math]::Floor($x * (2000 - $x) / 1000) }

$InTicks = SecToTicks $ex.In
$H1Ticks = SecToTicks $ex.H1
$ExTicks = SecToTicks $ex.Ex
$H2Ticks = SecToTicks $ex.H2
$CycleTicks = $InTicks + $H1Ticks + $ExTicks + $H2Ticks

$BarMax = 20

# Build bar strings
$Bar = @("")
for ($i = 1; $i -le $BarMax; $i++) { $Bar += ($Bar[$i-1] + [char]0x2588) }

function CenterText($row, $text, $rawLen) {
    if (-not $rawLen) { $rawLen = ($text -replace "`e\[[^m]*m", "").Length }
    $col = [math]::Max(1, [math]::Floor((36 - $rawLen) / 2) + 1)
    Write-Host -NoNewline "`e[${row};1H`e[2K`e[${row};${col}H$text"
}

# Hide cursor, clear screen, set title
Write-Host -NoNewline "`e]0;HushFlow`a`e[?25l`e[2J"

$tick = 0

try {
    while ($true) {
        if (-not (Test-Path $MarkerFile)) { break }

        $t = $tick % $CycleTicks

        if ($t -lt $InTicks) {
            $phase = "inhale"; $color = $ColorIn
            $remainTicks = $InTicks - $t
            $linear = [math]::Floor($t * 1000 / [math]::Max(1, $InTicks))
            if ($ex.Type -eq "double_inhale") {
                $progress = [math]::Floor((Ease $linear) * 850 / 1000)
            } else {
                $progress = Ease $linear
            }
        } elseif ($t -lt ($InTicks + $H1Ticks)) {
            $remainTicks = $InTicks + $H1Ticks - $t
            if ($ex.Type -eq "double_inhale") {
                $phase = "sip"; $color = $ColorIn
                $pt = $t - $InTicks
                $linear = [math]::Floor($pt * 1000 / [math]::Max(1, $H1Ticks))
                $progress = 850 + [math]::Floor((Ease $linear) * 150 / 1000)
            } else {
                $phase = "hold"; $color = $ColorIn
                $progress = 1000
            }
        } elseif ($t -lt ($InTicks + $H1Ticks + $ExTicks)) {
            $phase = "exhale"; $color = $ColorOut
            $remainTicks = $InTicks + $H1Ticks + $ExTicks - $t
            $pt = $t - $InTicks - $H1Ticks
            $linear = [math]::Floor($pt * 1000 / [math]::Max(1, $ExTicks))
            $progress = 1000 - (Ease $linear)
        } else {
            $phase = "hold"; $color = $ColorOut
            $remainTicks = $CycleTicks - $t
            $progress = 0
        }

        $fill = [math]::Floor($BarMax * $progress / 1000)
        if ($fill -lt 1 -and $progress -gt 0) { $fill = 1 }
        $empty = $BarMax - $fill
        $remainS = [math]::Ceiling($remainTicks / $TickRate)
        $spaces = " " * $empty

        Write-Host -NoNewline "`e[H"
        CenterText 2 "${color}HushFlow${Reset}" 8
        CenterText 4 "${Dim}$($ex.Name)${Reset}" $ex.Name.Length
        CenterText 6 "${color}[$($Bar[$fill])${spaces}]${Reset}" ($BarMax + 2)
        $phaseText = "$phase  ${remainS}s"
        CenterText 8 "${color}${phaseText}${Reset}" $phaseText.Length
        CenterText 10 "${Dim}Esc to close${Reset}" 12

        Start-Sleep -Milliseconds 100
        $tick++
    }
} finally {
    Write-Host -NoNewline "`e[?25h`e[0m`e[2J"
}
