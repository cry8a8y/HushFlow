# HushFlow - Hook: Called when AI starts working (Windows)
$MarkerFile = "$env:TEMP\hushflow-working"
$PidFile = "$env:TEMP\hushflow-window-pid"
$LockFile = "$env:TEMP\hushflow-ui.lock"
$ScriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ConfigFile = "$env:USERPROFILE\.claude\hushflow\config"

# Exit if disabled
if (Test-Path $ConfigFile) {
    $enabled = Get-Content $ConfigFile | Where-Object { $_ -match "^enabled=false" }
    if ($enabled) { exit 0 }
}

# Clean up leftover processes
if (Test-Path $PidFile) {
    $oldPid = Get-Content $PidFile
    Stop-Process -Id $oldPid -ErrorAction SilentlyContinue
    Remove-Item $PidFile -ErrorAction SilentlyContinue
}

# Create marker file
Get-Date -UFormat "%s" | Out-File -FilePath $MarkerFile -NoNewline

# Read UI mode
$uiMode = $env:HUSHFLOW_UI_MODE
if (-not $uiMode) { $uiMode = "window" }

if ($uiMode -eq "off") { exit 0 }

# Read delay
$delay = 5
if (Test-Path $ConfigFile) {
    $line = Get-Content $ConfigFile | Where-Object { $_ -match "^delay=" }
    if ($line) { $delay = [int](($line -split "=")[1]) }
}
if ($env:HUSHFLOW_DELAY_SECONDS) { $delay = [int]$env:HUSHFLOW_DELAY_SECONDS }

# Launch breathing animation in a new window after delay
$breatheScript = Join-Path $ScriptDir "breathe-compact.ps1"
Start-Job -ScriptBlock {
    param($delay, $marker, $script, $pidFile)
    Start-Sleep -Seconds $delay
    if (-not (Test-Path $marker)) { return }
    $proc = Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$script`"" -PassThru -WindowStyle Normal
    $proc.Id | Out-File -FilePath $pidFile -NoNewline
} -ArgumentList $delay, $MarkerFile, $breatheScript, $PidFile | Out-Null
