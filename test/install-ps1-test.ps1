# HushFlow PowerShell Installer Tests
# Tests install.ps1 for Claude / Gemini / Codex targets
# Usage: pwsh test/install-ps1-test.ps1
#
# No Pester dependency — pure PowerShell assertions

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$InstallerPath = Join-Path $ProjectDir "install.ps1"

$Passed = 0
$Failed = 0

function Pass($msg) {
    $script:Passed++
    Write-Host "  PASS: $msg"
}
function Fail($msg) {
    $script:Failed++
    Write-Host "  FAIL: $msg" -ForegroundColor Red
}
function Section($msg) {
    Write-Host ""
    Write-Host "=== $msg ==="
}

function New-TestHome {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("hf-test-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    return $tmp
}

function Run-Install($testHome, $target) {
    $env:USERPROFILE = $testHome
    & $InstallerPath -Target $target 2>$null
}

function Run-Uninstall($testHome) {
    $env:USERPROFILE = $testHome
    & $InstallerPath -Uninstall 2>$null
}

$TestDirs = @()

try {

    # ============================================================
    # Claude: Fresh install
    # ============================================================
    Section "Claude: Fresh install"

    $H = New-TestHome; $TestDirs += $H
    New-Item -ItemType Directory -Path "$H\.claude" -Force | Out-Null
    '{}' | Out-File "$H\.claude\settings.json" -Encoding utf8

    Run-Install $H "claude"

    $sf = "$H\.claude\settings.json"
    if (Test-Path $sf) {
        $json = Get-Content $sf -Raw | ConvertFrom-Json
        # Check hooks exist
        if ($json.hooks.UserPromptSubmit) { Pass "claude: UserPromptSubmit hook exists" }
        else { Fail "claude: UserPromptSubmit hook missing" }

        if ($json.hooks.Stop) { Pass "claude: Stop hook exists" }
        else { Fail "claude: Stop hook missing" }

        # Check async attribute
        $startHook = $json.hooks.UserPromptSubmit[0].hooks[0]
        if ($startHook.async -eq $true) { Pass "claude: start hook async=true" }
        else { Fail "claude: start hook async != true (got $($startHook.async))" }

        # Check command contains on-start
        if ($startHook.command -match "on-start") { Pass "claude: start command contains on-start" }
        else { Fail "claude: start command missing on-start" }
    } else {
        Fail "claude: settings.json not created"
    }

    # Check config
    $cf = "$H\.claude\hushflow\config"
    if (Test-Path $cf) {
        $content = Get-Content $cf -Raw
        Pass "claude: config file created"
        if ($content -match "animation=constellation") { Pass "claude: animation default present" }
        else { Fail "claude: animation default missing" }
        if ($content -match "enabled=true") { Pass "claude: enabled=true" }
        else { Fail "claude: enabled missing" }
        if ($content -match "theme=teal") { Pass "claude: theme=teal" }
        else { Fail "claude: theme missing" }
    } else {
        Fail "claude: config file not created"
    }

    # ============================================================
    # Claude: Idempotency
    # ============================================================
    Section "Claude: Idempotency — double install"

    $H = New-TestHome; $TestDirs += $H
    New-Item -ItemType Directory -Path "$H\.claude" -Force | Out-Null
    '{}' | Out-File "$H\.claude\settings.json" -Encoding utf8

    Run-Install $H "claude"
    Run-Install $H "claude"

    $sf = "$H\.claude\settings.json"
    $json = Get-Content $sf -Raw | ConvertFrom-Json
    $startCount = @($json.hooks.UserPromptSubmit).Count
    if ($startCount -eq 1) { Pass "claude-idempotent: exactly 1 start hook group" }
    else { Fail "claude-idempotent: $startCount start hook groups (expected 1)" }

    $stopCount = @($json.hooks.Stop).Count
    if ($stopCount -eq 1) { Pass "claude-idempotent: exactly 1 stop hook group" }
    else { Fail "claude-idempotent: $stopCount stop hook groups (expected 1)" }

    # ============================================================
    # Claude: Preserve existing hooks
    # ============================================================
    Section "Claude: Existing hooks preserved"

    $H = New-TestHome; $TestDirs += $H
    New-Item -ItemType Directory -Path "$H\.claude" -Force | Out-Null
    $existing = @{
        hooks = @{
            UserPromptSubmit = @(
                @{ hooks = @(@{ type = "command"; command = "echo other-tool"; async = $true }) }
            )
        }
    } | ConvertTo-Json -Depth 10
    $existing | Out-File "$H\.claude\settings.json" -Encoding utf8

    Run-Install $H "claude"

    $json = Get-Content "$H\.claude\settings.json" -Raw | ConvertFrom-Json
    $allCommands = @($json.hooks.UserPromptSubmit | ForEach-Object { $_.hooks } | ForEach-Object { $_.command })
    $hasOther = $allCommands | Where-Object { $_ -match "other-tool" }
    $hasHushflow = $allCommands | Where-Object { $_ -match "on-start" }
    if ($hasOther) { Pass "claude-existing: other hook preserved" }
    else { Fail "claude-existing: other hook lost" }
    if ($hasHushflow) { Pass "claude-existing: HushFlow hook added" }
    else { Fail "claude-existing: HushFlow hook missing" }

    # ============================================================
    # Claude: Uninstall
    # ============================================================
    Section "Claude: Uninstall"

    $H = New-TestHome; $TestDirs += $H
    New-Item -ItemType Directory -Path "$H\.claude" -Force | Out-Null
    '{}' | Out-File "$H\.claude\settings.json" -Encoding utf8
    Run-Install $H "claude"
    Run-Uninstall $H

    $sf = "$H\.claude\settings.json"
    if (Test-Path $sf) {
        $json = Get-Content $sf -Raw | ConvertFrom-Json
        $hasStart = $false
        if ($json.hooks -and $json.hooks.UserPromptSubmit) {
            foreach ($group in $json.hooks.UserPromptSubmit) {
                foreach ($hook in $group.hooks) {
                    if ($hook.command -match "on-start") { $hasStart = $true }
                }
            }
        }
        if (-not $hasStart) { Pass "claude-uninstall: HushFlow hooks removed" }
        else { Fail "claude-uninstall: HushFlow hooks still present" }
    } else {
        Pass "claude-uninstall: settings.json cleaned"
    }

    $configDir = "$H\.claude\hushflow"
    if (-not (Test-Path $configDir)) { Pass "claude-uninstall: config dir removed" }
    else { Fail "claude-uninstall: config dir still exists" }

    # ============================================================
    # Gemini: Fresh install
    # ============================================================
    Section "Gemini: Fresh install"

    $H = New-TestHome; $TestDirs += $H
    New-Item -ItemType Directory -Path "$H\.gemini" -Force | Out-Null
    '{}' | Out-File "$H\.gemini\settings.json" -Encoding utf8

    Run-Install $H "gemini"

    $sf = "$H\.gemini\settings.json"
    $json = Get-Content $sf -Raw | ConvertFrom-Json
    if ($json.hooks.BeforeAgent) { Pass "gemini: BeforeAgent hook exists" }
    else { Fail "gemini: BeforeAgent hook missing" }
    if ($json.hooks.AfterAgent) { Pass "gemini: AfterAgent hook exists" }
    else { Fail "gemini: AfterAgent hook missing" }

    $startHook = $json.hooks.BeforeAgent[0].hooks[0]
    if ($startHook.timeout -eq 60000) { Pass "gemini: start timeout=60000" }
    else { Fail "gemini: start timeout=$($startHook.timeout) (expected 60000)" }

    $stopHook = $json.hooks.AfterAgent[0].hooks[0]
    if ($stopHook.timeout -eq 5000) { Pass "gemini: stop timeout=5000" }
    else { Fail "gemini: stop timeout=$($stopHook.timeout) (expected 5000)" }

    # ============================================================
    # Codex: Fresh install
    # ============================================================
    Section "Codex: Fresh install"

    $H = New-TestHome; $TestDirs += $H
    New-Item -ItemType Directory -Path "$H\.codex" -Force | Out-Null
    '{}' | Out-File "$H\.codex\hooks.json" -Encoding utf8

    Run-Install $H "codex"

    $sf = "$H\.codex\hooks.json"
    $json = Get-Content $sf -Raw | ConvertFrom-Json
    if ($json.hooks.SessionStart) { Pass "codex: SessionStart hook exists" }
    else { Fail "codex: SessionStart hook missing" }
    if ($json.hooks.Stop) { Pass "codex: Stop hook exists" }
    else { Fail "codex: Stop hook missing" }

    $startHook = $json.hooks.SessionStart[0].hooks[0]
    if ($startHook.timeout -eq 60) { Pass "codex: start timeout=60" }
    else { Fail "codex: start timeout=$($startHook.timeout) (expected 60)" }

    # ============================================================
    # Summary
    # ============================================================
    Write-Host ""
    Write-Host "================================"
    $Total = $Passed + $Failed
    Write-Host "  Results: $Passed/$Total passed"
    if ($Failed -gt 0) {
        Write-Host "  $Failed test(s) FAILED" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "  All tests passed!"
    }

} finally {
    # Cleanup test directories
    foreach ($dir in $TestDirs) {
        if (Test-Path $dir) { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
