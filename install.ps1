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
        "enabled=true`nexercise=0`ndelay=5`ntheme=teal`nanimation=constellation`nsound=true" | Out-File -FilePath $configFile -Encoding utf8 -NoNewline
        Write-Host "  Created config at $configFile"
    }
}

function Has-HushFlowHook($settings, $eventName, $needle) {
    if (-not $settings.hooks) { return $false }
    $eventHooks = $settings.hooks.$eventName
    if (-not $eventHooks) { return $false }
    foreach ($group in $eventHooks) {
        foreach ($hook in $group.hooks) {
            if ($hook.command -and $hook.command.Contains($needle)) { return $true }
        }
    }
    return $false
}

function Remove-HushFlowHooks($settings, $eventName, $needle) {
    if (-not $settings.hooks -or -not $settings.hooks.$eventName) { return $settings }
    $filtered = @($settings.hooks.$eventName | Where-Object {
        $dominated = $false
        foreach ($hook in $_.hooks) {
            if ($hook.command -and $hook.command.Contains($needle)) { $dominated = $true }
        }
        -not $dominated
    })
    if ($filtered.Count -eq 0) {
        $settings.hooks.PSObject.Properties.Remove($eventName)
    } else {
        $settings.hooks.$eventName = $filtered
    }
    return $settings
}

function Write-ValidJson($settings, $dest) {
    $json = $settings | ConvertTo-Json -Depth 10
    try {
        $null = $json | ConvertFrom-Json
    } catch {
        Write-Host "  ERROR: produced invalid JSON. Aborting write to $dest" -ForegroundColor Red
        return $false
    }
    if (Test-Path $dest) { Copy-Item $dest "$dest.backup" -Force }
    $json | Out-File -FilePath $dest -Encoding utf8
    return $true
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
            $settings = if (Test-Path $settingsFile) { Get-Content $settingsFile -Raw | ConvertFrom-Json } else { [PSCustomObject]@{} }
            $hasStart = Has-HushFlowHook $settings "UserPromptSubmit" "on-start"
            $hasStop = Has-HushFlowHook $settings "Stop" "on-stop"
            if ($hasStart -and $hasStop) { Write-Host "  Hooks already installed."; return }
            if (-not $settings.hooks) { $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([PSCustomObject]@{}) }
            if (-not $hasStart) {
                $startHook = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File `"$OnStart`""; async = $true }) })
                if ($settings.hooks.UserPromptSubmit) {
                    $settings.hooks.UserPromptSubmit = @($settings.hooks.UserPromptSubmit) + $startHook
                } else {
                    $settings.hooks | Add-Member -NotePropertyName "UserPromptSubmit" -NotePropertyValue $startHook
                }
            }
            if (-not $hasStop) {
                $stopHook = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File `"$OnStop`""; async = $true }) })
                if ($settings.hooks.Stop) {
                    $settings.hooks.Stop = @($settings.hooks.Stop) + $stopHook
                } else {
                    $settings.hooks | Add-Member -NotePropertyName "Stop" -NotePropertyValue $stopHook
                }
            }
            if (Write-ValidJson $settings $settingsFile) { Write-Host "  Hooks installed to $settingsFile" }
        }
        "gemini" {
            $settingsDir = "$env:USERPROFILE\.gemini"
            $settingsFile = "$settingsDir\settings.json"
            $configDir = "$settingsDir\hushflow"
            Write-Host "Installing for Gemini CLI..."
            if (-not (Test-Path $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null }
            Ensure-Config $configDir
            $settings = if (Test-Path $settingsFile) { Get-Content $settingsFile -Raw | ConvertFrom-Json } else { [PSCustomObject]@{} }
            $hasStart = Has-HushFlowHook $settings "BeforeAgent" "on-start"
            $hasStop = Has-HushFlowHook $settings "AfterAgent" "on-stop"
            if ($hasStart -and $hasStop) { Write-Host "  Hooks already installed."; return }
            if (-not $settings.hooks) { $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([PSCustomObject]@{}) }
            if (-not $hasStart) {
                $startHook = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File `"$OnStart`""; timeout = 60000 }) })
                if ($settings.hooks.BeforeAgent) {
                    $settings.hooks.BeforeAgent = @($settings.hooks.BeforeAgent) + $startHook
                } else {
                    $settings.hooks | Add-Member -NotePropertyName "BeforeAgent" -NotePropertyValue $startHook
                }
            }
            if (-not $hasStop) {
                $stopHook = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File `"$OnStop`""; timeout = 5000 }) })
                if ($settings.hooks.AfterAgent) {
                    $settings.hooks.AfterAgent = @($settings.hooks.AfterAgent) + $stopHook
                } else {
                    $settings.hooks | Add-Member -NotePropertyName "AfterAgent" -NotePropertyValue $stopHook
                }
            }
            if (Write-ValidJson $settings $settingsFile) { Write-Host "  Hooks installed to $settingsFile" }
        }
        "codex" {
            $hooksDir = "$env:USERPROFILE\.codex"
            $hooksFile = "$hooksDir\hooks.json"
            $configDir = "$hooksDir\hushflow"
            Write-Host "Installing for Codex CLI..."
            if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null }
            Ensure-Config $configDir
            $settings = if (Test-Path $hooksFile) { Get-Content $hooksFile -Raw | ConvertFrom-Json } else { [PSCustomObject]@{} }
            $hasStart = Has-HushFlowHook $settings "SessionStart" "on-start"
            $hasStop = Has-HushFlowHook $settings "Stop" "on-stop"
            if ($hasStart -and $hasStop) { Write-Host "  Hooks already installed."; return }
            if (-not $settings.hooks) { $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue ([PSCustomObject]@{}) }
            if (-not $hasStart) {
                $startHook = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File `"$OnStart`""; timeout = 60 }) })
                if ($settings.hooks.SessionStart) {
                    $settings.hooks.SessionStart = @($settings.hooks.SessionStart) + $startHook
                } else {
                    $settings.hooks | Add-Member -NotePropertyName "SessionStart" -NotePropertyValue $startHook
                }
            }
            if (-not $hasStop) {
                $stopHook = @(@{ hooks = @(@{ type = "command"; command = "powershell -ExecutionPolicy Bypass -File `"$OnStop`""; timeout = 5 }) })
                if ($settings.hooks.Stop) {
                    $settings.hooks.Stop = @($settings.hooks.Stop) + $stopHook
                } else {
                    $settings.hooks | Add-Member -NotePropertyName "Stop" -NotePropertyValue $stopHook
                }
            }
            if (Write-ValidJson $settings $hooksFile) { Write-Host "  Hooks installed to $hooksFile" }
        }
    }
}

# --- Main ---

function Uninstall-ForTool($tool) {
    switch ($tool) {
        "claude" {
            $sf = "$env:USERPROFILE\.claude\settings.json"
            if (Test-Path $sf) {
                $settings = Get-Content $sf -Raw | ConvertFrom-Json
                $settings = Remove-HushFlowHooks $settings "UserPromptSubmit" "on-start"
                $settings = Remove-HushFlowHooks $settings "Stop" "on-stop"
                if ($settings.hooks -and @($settings.hooks.PSObject.Properties).Count -eq 0) {
                    $settings.PSObject.Properties.Remove("hooks")
                }
                Write-ValidJson $settings $sf | Out-Null
                Write-Host "  Removed Claude Code hooks"
            }
            $dir = "$env:USERPROFILE\.claude\hushflow"
            if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
        }
        "gemini" {
            $sf = "$env:USERPROFILE\.gemini\settings.json"
            if (Test-Path $sf) {
                $settings = Get-Content $sf -Raw | ConvertFrom-Json
                $settings = Remove-HushFlowHooks $settings "BeforeAgent" "on-start"
                $settings = Remove-HushFlowHooks $settings "AfterAgent" "on-stop"
                if ($settings.hooks -and @($settings.hooks.PSObject.Properties).Count -eq 0) {
                    $settings.PSObject.Properties.Remove("hooks")
                }
                Write-ValidJson $settings $sf | Out-Null
                Write-Host "  Removed Gemini CLI hooks"
            }
            $dir = "$env:USERPROFILE\.gemini\hushflow"
            if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
        }
        "codex" {
            $sf = "$env:USERPROFILE\.codex\hooks.json"
            if (Test-Path $sf) {
                $settings = Get-Content $sf -Raw | ConvertFrom-Json
                $settings = Remove-HushFlowHooks $settings "SessionStart" "on-start"
                $settings = Remove-HushFlowHooks $settings "Stop" "on-stop"
                if ($settings.hooks -and @($settings.hooks.PSObject.Properties).Count -eq 0) {
                    $settings.PSObject.Properties.Remove("hooks")
                }
                Write-ValidJson $settings $sf | Out-Null
                Write-Host "  Removed Codex CLI hooks"
            }
            $dir = "$env:USERPROFILE\.codex\hushflow"
            if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
        }
    }
}

if ($Uninstall) {
    Write-Host "Uninstalling HushFlow..."
    Remove-Item "$env:TEMP\hushflow-*" -ErrorAction SilentlyContinue
    Uninstall-ForTool "claude"
    Uninstall-ForTool "gemini"
    Uninstall-ForTool "codex"
    Write-Host "Done."
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
