# HushFlow - Hook: Called when AI stops working (Windows)
$MarkerFile = "$env:TEMP\hushflow-working"
$PidFile = "$env:TEMP\hushflow-window-pid"

# Remove marker (triggers animation auto-close)
Remove-Item $MarkerFile -ErrorAction SilentlyContinue

# Kill breathing window process
if (Test-Path $PidFile) {
    $pid = Get-Content $PidFile
    Stop-Process -Id $pid -ErrorAction SilentlyContinue
    Remove-Item $PidFile -ErrorAction SilentlyContinue
}
