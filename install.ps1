# HushFlow Installer for Windows
# Supports: Claude Code, Gemini CLI, Codex CLI
# Usage: .\install.ps1 [-Target claude|gemini|codex] [-Uninstall]

param(
    [string]$Target = "",
    [switch]$Uninstall
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OnStart = Join-Path $ScriptDir "hooks\on-start.ps1"
$OnStop = Join-Path $ScriptDir "hooks\on-stop.ps1"

function Ensure-Config($configDir) {
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    $configFile = Join-Path $configDir "config"
    if (-not (Test-Path $configFile)) {
        "enabled=true`nexercise=0`ndelay=5`ntheme=teal" | Out-File -FilePath $configFile -Encoding utf8 -NoNewline
        Write-Host "  Created config at $configFile"
    }
}

function Install-ForTool($tool) {
    switch ($tool) {
        "claude" {
            $settingsDir = "$env:USERPROFILE\.claude"
            $settingsFile = "$settingsDir\settings.json"
            $configDir = "$settingsDir\hushflow"
            Write-Host "Installing for Claude Code..."
            if (-not (Test-Path $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null }
            Ensure-Config $configDir
            # Write hooks to settings.json
            $settings = if (Test-Path $settingsFile) { Get-Content $settingsFile -Raw | ConvertFrom-Json } else { @{} }
            # Backup settings before modifying
            if (Test-Path $settingsFile) { Copy-Item $settingsFile "$settingsFile.bak" -Force }
            if (-not $settings.hooks) { $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue @{} }
            $startHook = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File `"$OnStart`""; async = $true }) })
            $stopHook = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File `"$OnStop`""; async = $true }) })
            $settings.hooks | Add-Member -NotePropertyName "UserPromptSubmit" -NotePropertyValue $startHook -Force
            $settings.hooks | Add-Member -NotePropertyName "Stop" -NotePropertyValue $stopHook -Force
            $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding utf8
            Write-Host "  Hooks installed to $settingsFile"
        }
        "gemini" {
            $settingsDir = "$env:USERPROFILE\.gemini"
            $settingsFile = "$settingsDir\settings.json"
            $configDir = "$settingsDir\hushflow"
            Write-Host "Installing for Gemini CLI..."
            if (-not (Test-Path $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null }
            Ensure-Config $configDir
            $settings = if (Test-Path $settingsFile) { Get-Content $settingsFile -Raw | ConvertFrom-Json } else { @{} }
            if (-not $settings.hooks) { $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue @{} }
            $startHook = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File `"$OnStart`""; timeout = 60000 }) })
            $stopHook = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File `"$OnStop`""; timeout = 5000 }) })
            $settings.hooks | Add-Member -NotePropertyName "BeforeAgent" -NotePropertyValue $startHook -Force
            $settings.hooks | Add-Member -NotePropertyName "AfterAgent" -NotePropertyValue $stopHook -Force
            $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsFile -Encoding utf8
            Write-Host "  Hooks installed to $settingsFile"
        }
        "codex" {
            $hooksDir = "$env:USERPROFILE\.codex"
            $hooksFile = "$hooksDir\hooks.json"
            $configDir = "$hooksDir\hushflow"
            Write-Host "Installing for Codex CLI..."
            if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null }
            Ensure-Config $configDir
            $settings = if (Test-Path $hooksFile) { Get-Content $hooksFile -Raw | ConvertFrom-Json } else { @{} }
            if (-not $settings.hooks) { $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue @{} }
            $startHook = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File `"$OnStart`""; timeout = 60 }) })
            $stopHook = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File `"$OnStop`""; timeout = 5 }) })
            $settings.hooks | Add-Member -NotePropertyName "SessionStart" -NotePropertyValue $startHook -Force
            $settings.hooks | Add-Member -NotePropertyName "Stop" -NotePropertyValue $stopHook -Force
            $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $hooksFile -Encoding utf8
            Write-Host "  Hooks installed to $hooksFile"
        }
    }
}

# --- Main ---

if ($Uninstall) {
    Write-Host "Uninstalling HushFlow..."
    Remove-Item "$env:TEMP\hushflow-*" -ErrorAction SilentlyContinue
    foreach ($tool in @("claude", "gemini", "codex")) {
        $dir = "$env:USERPROFILE\.$tool\hushflow"
        if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
    }
    Write-Host "Done. You may need to manually remove hooks from settings files."
    exit 0
}

Write-Host ""
Write-Host "  HushFlow"
Write-Host "  Turn AI thinking time into mindful breathing."
Write-Host ""

if ($Target) {
    Install-ForTool $Target
} else {
    $installed = 0
    if (Test-Path "$env:USERPROFILE\.claude") { Install-ForTool "claude"; $installed++ }
    if (Test-Path "$env:USERPROFILE\.gemini") { Install-ForTool "gemini"; $installed++ }
    if (Test-Path "$env:USERPROFILE\.codex")  { Install-ForTool "codex";  $installed++ }
    if ($installed -eq 0) {
        Write-Host "No AI tools detected. Installing for Claude Code by default."
        Install-ForTool "claude"
    }
}

Write-Host ""
Write-Host "Restart your AI tool for hooks to take effect."
