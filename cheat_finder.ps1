# ===================== BEGIN SCRIPT =====================

# Timer start
$startTime = Get-Date

# Initial UI
Write-Host "  ____ _   _ _____    _  _____   _____ ___ _   _ ____  _____ ____  " -ForegroundColor Green
Write-Host " / ___| | | | ____|  / \|_   _| |  ___|_ _| \ | |  _ \| ____|  _ \ " -ForegroundColor Green
Write-Host "| |   | |_| |  _|   / _ \ | |   | |_   | ||  \| | | | |  _| | |_) |" -ForegroundColor Green
Write-Host "| |___|  _  | |___ / ___ \| |   |  _|  | || |\  | |_| | |___|  _ < " -ForegroundColor Green
Write-Host " \____|_| |_|_____/_/   \_\_|   |_|   |___|_| \_|____/|_____|_| \_\" -ForegroundColor Green
Write-Host ""
Write-Host "  LOC Powershell Code, Slightly Modified To Stop Bypassing/Cleaners | @8wl5 on Discord  " -ForegroundColor Blue -NoNewline
Write-Host ""


# Section outputs
$exclusionsOutput = @()
$threatsOutput = @()
$memoryIntegrityOutput = @()
$defenderOutput = @()
$exploitOutput = @()
$prefetchOutput = @()
$keyAuthOutput = @()
$registryOutput = @()
$pahOutput = @("SUCCESS: PAH initiated successfully, DO NOT CLOSE PAH AT ALL TIMES.")
$deletedPrefetchOutput = @()
$deletedMuiCacheOutput = @()
$userAssistOutput = @()
$deletedMuiCacheOutput = @()
$bamOutput = @()
$jumpListOutput = @()

# Blacklist definitions
$blacklist = @("matcha", "olduimatrix", "autoexe", "bin", "workspace", "monkeyaim", "thunderaim", "thunderclient", "celex", "release", "matrix", "matcha.exe", "triggerbot", "solara", "xeno", "wave", "cloudy", "tupical", "horizon", "myst", "celery", "zarora", "juju", "nezure", "FusionHacks.zip", "release.zip", "bootstrapper", "aimmy.exe", "aimmy", "Fluxus", "clumsy", "build", "build.zip", "build.rar", "MystW.exe", "isabelle", "dx9", "dx9ware")
$suspiciousList = @("isabelle", "xeno", "solara", "bootstrapper", "bootstrappernew", "loader", "santoware", "mystw", "severe", "mapper", "thunderclient", "monkeyaim", "olduimatrix", "matrix", "matcha")
$watchlist = @("BOOTSTRAPPERNEW.EXE", "BOOTSTRAPPER.EXE", "XENO.EXE", "XENOUI.EXE", "SOLARA.EXE", "MAPPER.EXE", "LOADER.EXE", "MATCHA.EXE", "EVOLVE.EXE")

# --- Exclusion Check ---
try {
    $exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath

    if ($exclusions) {
        $exclusionsOutput += "FAILURE: Exclusion paths detected:"
        $exclusionsOutput += $exclusions
    }
    else {
        $exclusionsOutput += "SUCCESS: No Exclusions were found at the moment."
    }
}
catch {
    $exclusionsOutput += "WARNING: Could not get exclusion paths. MUST RUN AS ADMINISTRATOR!"
}

Write-Progress -Activity "CheatFinder Scan" `
    -Status "Exclusions Complete" `
    -PercentComplete 10

# --- Threats Check ---
try {
    Import-Module Defender -ErrorAction SilentlyContinue
    $threats = Get-MpThreatDetection
    $activeThreats = $threats | Where-Object { $_.ThreatStatus -eq "Active" -and $_.QuarantineStatus -ne "Quarantined" }
    if ($activeThreats) {
        foreach ($t in $activeThreats) {
            $threatsOutput += "FAILURE: Threat detected - Name: $($t.ThreatName), Severity: $($t.Severity), Path: $($t.Path), Detected: $($t.DetectionTime)"
        }
    } else {
        $threatsOutput += "SUCCESS: No active threats that are not quarantined."
    }
} catch {
    $threatsOutput += "WARNING: Threat scan could not complete."
}

Write-Progress -Activity "CheatFinder Scan" `
    -Status "Threat Scan Complete" `
    -PercentComplete 20

# --- Memory Integrity & Blocklist ---
try {
    $miReg = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
    $vbReg = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config" 
    $memOn = Get-ItemPropertyValue -Path $miReg -Name "Enabled" -ErrorAction Stop
    $vbOn = $false
    try {
        $vbStatus = Get-ItemPropertyValue -Path $vbReg -Name "VulnerableBlocklistStatus"
        if ($vbStatus -eq 1) { $vbOn = $true }
    } catch {}
    if ($memOn -eq 1 -or $vbOn) {
        $memoryIntegrityOutput += "SUCCESS: Memory integrity is enabled or Vulnerable Blocklist is active."
    } else {
        $memoryIntegrityOutput += "FAILURE: Memory integrity and blocklist are both disabled."
    }
} catch {
    $memoryIntegrityOutput += "WARNING: Unable to verify memory integrity."
}

Write-Progress -Activity "CheatFinder Scan" `
    -Status "Memory Integrity Complete" `
    -PercentComplete 30

# --- Defender Check ---
try {
    $defender = Get-MpComputerStatus
    if ($defender.AMServiceEnabled -and $defender.RealTimeProtectionEnabled) {
        $defenderOutput += "SUCCESS: Windows Defender real-time protection is ENABLED."
    } else {
        $defenderOutput += "FAILURE: Windows Defender real-time protection is DISABLED."
    }
} catch {
    $defenderOutput += "WARNING: Could not assess Defender status."
}

Write-Progress -Activity "CheatFinder Scan" `
    -Status "Defender Check Complete" `
    -PercentComplete 40

# --- Exploit Check ---
try {

    $found = Test-Path "$env:APPDATA\Isabelle"

    if ($found) {
        $exploitOutput += "FAILURE: Isabelle exploit folder found."
    }
    else {
        $exploitOutput += "SUCCESS: No exploit signs found."
    }

}
catch {
    $exploitOutput += "WARNING: Exploit check could not be completed."
}

Write-Progress -Activity "CheatFinder Scan" `
    -Status "Exploit Check Complete" `
    -PercentComplete 50

# --- Prefetch ---
try {
    $now = Get-Date
    $pfFiles = Get-ChildItem "C:\Windows\Prefetch" -Filter "*.pf"
    foreach ($pf in $pfFiles) {
        $name = $pf.BaseName.ToUpper()
        $lastWrite = $pf.LastWriteTime
        $age = [math]::Round(($now - $lastWrite).TotalHours, 2)
        if ($watchlist -contains "$name.EXE") {
            $prefetchOutput += "WARNING: Suspicious prefetch file: $name | $age hours ago"
        } else {
            $prefetchOutput += "Detected: $name | $age hrs ago"
        }
    }
} catch {
    $prefetchOutput += "WARNING: Could not access prefetch."
}

Write-Progress -Activity "CheatFinder Scan" `
    -Status "Prefetch Scan Complete" `
    -PercentComplete 60

# --- Deleted Prefetches Check (FIXED + USN HEALTH CHECK) ---
try {

    $prefetchPath = "C:\Windows\Prefetch"

    # Check if USN Journal exists
    try {
        $journal = fsutil usn queryjournal C: 2>$null

        if (-not $journal) {
            $deletedPrefetchOutput += "WARNING: USN Journal unavailable or recently deleted."
        }
    }
    catch {
        $deletedPrefetchOutput += "WARNING: Unable to access USN Journal."
    }

    $pfFiles = Get-ChildItem $prefetchPath -Filter "*.pf" -ErrorAction SilentlyContinue
    $pfCount = $pfFiles.Count

    # Low prefetch count warning
    if ($pfCount -lt 50) {
        $deletedPrefetchOutput += "WARNING: Prefetch folder contains unusually few files ($pfCount)."
    }

    # Event log clear detection
    $clearedLogs = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Id      = @(104,1102)
    } -ErrorAction SilentlyContinue -MaxEvents 1

    if ($clearedLogs) {
        $deletedPrefetchOutput += "WARNING: Event Log history was recently cleared."
    }

    # USN deleted prefetch detection
    $usnDeleted = fsutil usn readjournal C: csv 2>$null |
        findstr /I "\.pf" |
        findstr /I "delete"

    $uniqueFiles = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($line in $usnDeleted) {

        if ($line -match '([A-Za-z0-9_\-]+\.PF)') {

            $file = $Matches[1].ToUpper()

            if (
                $file.Length -gt 8 -and
                $file -notmatch '^[A-Z0-9]{6,8}\.PF$'
            ) {
                $null = $uniqueFiles.Add($file)
            }
        }
    }

    foreach ($file in ($uniqueFiles | Sort-Object)) {
        $deletedPrefetchOutput += "WARNING: Deleted Prefetch File Detected -> $file"
    }

    if ($deletedPrefetchOutput.Count -eq 0) {
        $deletedPrefetchOutput += "SUCCESS: Prefetch folder structure and deletion logs look secure."
    }

}
catch {
    $deletedPrefetchOutput = @(
        "WARNING: Could not verify deleted prefetches."
    )
}

Write-Progress -Activity "CheatFinder Scan" `
    -Status "Deleted Prefetches Scan Complete" `
    -PercentComplete 70

# --- Deleted Muicaches Check (FIXED COUNT GLITCH) ---
try {
    $muiPath = "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    $muiKey = Get-Item -Path $muiPath
    
    # Correct key valuation to return a true integer item total count
    $muiCount = $muiKey.ValueCount
    if ($null -eq $muiCount) {
        $muiCount = ($muiKey.GetValueNames()).Count
    }
    
    if ($muiCount -lt 30) {
        $deletedMuiCacheOutput = "WARNING: MuiCache has suspiciously few entries ($muiCount). Key was cleared recently!"
    } else {
        $deletedMuiCacheOutput = "SUCCESS: MuiCache population looks normal ($muiCount entries)."
    }
} catch {
    $deletedMuiCacheOutput = "WARNING: Could not access MuiCache key structure."
}

Write-Progress -Activity "CheatFinder Scan" `
    -Status "MuiCache Check Complete" `
    -PercentComplete 80

# --- Key Checker ---
try {
    $folders = Get-ChildItem "C:\ProgramData\KeyAuth\debug" -Directory -ErrorAction Stop
    foreach ($f in $folders) {
        $keyAuthOutput += "FAILURE: External cheat/KeyAuth folder: $($f.Name)"
    }
} catch {
    $keyAuthOutput += "SUCCESS: No KeyAuth folders found."
}

Write-Progress -Activity "CheatFinder Scan" `
    -Status "KeyAuth Check Complete" `
    -PercentComplete 90

    # --- UserAssist Check ---
try {

    $userAssistPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"

    $count = (
        Get-ChildItem $userAssistPath -Recurse -ErrorAction SilentlyContinue
    ).Count

    if ($count -lt 5) {
        $userAssistOutput += "WARNING: UserAssist appears empty or recently cleared."
    }
    else {
        $userAssistOutput += "SUCCESS: UserAssist history appears normal."
    }

}
catch {
    $userAssistOutput += "WARNING: Could not verify UserAssist history."
}

Write-Progress -Activity "CheatFinder Scan" `
    -Status "UserAssist Check Complete" `
    -PercentComplete 85

# --- BAM Check ---
try {

    $bamPath = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"

    $bamCount = (
        Get-ChildItem $bamPath -Recurse -ErrorAction SilentlyContinue
    ).Count

    if ($bamCount -lt 5) {
        $bamOutput += "WARNING: BAM execution history appears unusually sparse."
    }
    else {
        $bamOutput += "SUCCESS: BAM execution history appears normal."
    }

}
catch {
    $bamOutput += "WARNING: Could not access BAM execution history."
}


Write-Progress -Activity "CheatFinder Scan" `
    -Status "BAM Check Complete" `
    -PercentComplete 88

# --- Jump List Check ---
try {

    $autoPath =
        "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations"

    $customPath =
        "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations"

    $count =
        (Get-ChildItem $autoPath -ErrorAction SilentlyContinue).Count +
        (Get-ChildItem $customPath -ErrorAction SilentlyContinue).Count

    if ($count -lt 5) {
        $jumpListOutput += "WARNING: Jump Lists appear unusually empty."
    }
    else {
        $jumpListOutput += "SUCCESS: Jump List history appears normal."
    }

}
catch {
    $jumpListOutput += "WARNING: Could not verify Jump Lists."
}

Write-Progress -Activity "CheatFinder Scan" `
    -Status "Jump List Check Complete" `
    -PercentComplete 92
    
# --- Registry Suspicious Check ---
try {
    $mui = "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    $entries = Get-ItemProperty -Path $mui
    foreach ($prop in $entries.PSObject.Properties) {
        $lower = $prop.Name.ToLower()
        foreach ($b in $blacklist) {
            if ($lower -like "*$b*") {
                if ($suspiciousList -contains $b) {
                    $registryOutput += "WARNING: Suspicious registry: $($prop.Name)"
                }
            }
        }
    }
} catch {
    $registryOutput += "WARNING: Cannot access MuiCache registry."
}

Write-Progress -Activity "CheatFinder Scan" `
    -Status "Registry Scan Complete" `
    -PercentComplete 100

# --- Show PAH Window ---
Start-Job {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    function Show-ProcessActiveHistory {
        $form = New-Object Windows.Forms.Form
        $form.Text = "Process Active History"
        $form.WindowState = 'Maximized'
        $form.MinimumSize = New-Object Drawing.Size(800, 600)
        $form.StartPosition = "CenterScreen"
        $form.BackColor = [Drawing.Color]::White
        $form.Topmost = $true

        $listBox = New-Object Windows.Forms.ListBox
        $listBox.Dock = 'Fill'
        $listBox.Font = New-Object Drawing.Font("Consolas", 10)
        $listBox.BackColor = [Drawing.Color]::White
        $listBox.ForeColor = [Drawing.Color]::Black
        $form.Controls.Add($listBox)

        $seen = [System.Collections.Generic.HashSet[string]]::new()
        $timer = New-Object Windows.Forms.Timer
        $timer.Interval = 2000
        $timer.Add_Tick({
            $procs = Get-Process | Where-Object { $_.MainWindowTitle -or $_.ProcessName }
            foreach ($p in $procs) {
                $name = $p.ProcessName
                if (-not $seen.Contains($name)) {
                    $seen.Add($name) | Out-Null
                    $stamp = Get-Date -Format "HH:mm:ss"
                    $msg = "[$stamp] Opened: $name"
                    $listBox.Invoke([action]{ $listBox.Items.Add($msg) }) | Out-Null
                }
            }
        })
        $timer.Start()
        $form.Add_Shown({ $form.Activate() })
        $form.Add_Closing({ $timer.Stop(); $timer.Dispose() })
        [void] $form.ShowDialog()
    }

    Show-ProcessActiveHistory
} | Out-Null

Write-Progress -Activity "CheatFinder Scan" -Completed

# --- Print Results with clean spacing layout ---
function Write-Section {
    param ([string]$Title, [string[]]$Lines)
    Write-Host "--- $Title ---" -ForegroundColor White
    
    foreach ($line in $Lines) {
        if ($line -match "^SUCCESS") {
            Write-Host $line -ForegroundColor Green
        } elseif ($line -match "^FAILURE") {
            if ($line -eq "FAILURE: Exclusion paths detected:") {
                Write-Host $line -ForegroundColor Red
            } else {
                # Indents the raw file path variables nicely below the failure label
                Write-Host "$line" -ForegroundColor Red
            }
        } elseif ($line -match "^WARNING") {
            Write-Host $line -ForegroundColor Yellow
        } else {
            Write-Host $line -ForegroundColor White
        }
    }
    Write-Host "" # Explicit layout spacing padding line
}

Write-Section "Jump Lists" $jumpListOutput
Write-Section "BAM History" $bamOutput
Write-Section "UserAssist" $userAssistOutput
Write-Section "Deleted Muicaches" $deletedMuiCacheOutput
Write-Section "Prefetch" $prefetchOutput
Write-Section "Deleted Prefetches" $deletedPrefetchOutput
Write-Section "Deleted Muicaches" $deletedMuiCacheOutput
Write-Section "Exclusions" $exclusionsOutput
Write-Section "Threats" $threatsOutput
Write-Section "Memory Integrity" $memoryIntegrityOutput
Write-Section "Windows Defender" $defenderOutput
Write-Section "Exploit Checker" $exploitOutput
Write-Section "Key Checker" $keyAuthOutput
Write-Section "Registry Scan" $registryOutput
Write-Section "PAH (Process Active History)" $pahOutput


# --- Summary ---

$cleanerScore = 0

if ($deletedPrefetchOutput -join "`n" -match "Deleted Prefetch") { $cleanerScore += 2 }

if ($deletedPrefetchOutput -join "`n" -match "USN Journal") { $cleanerScore += 2 }

if ($deletedMuiCacheOutput -join "`n" -match "WARNING") { $cleanerScore++ }

if ($userAssistOutput -join "`n" -match "WARNING") { $cleanerScore++ }

if ($bamOutput -join "`n" -match "WARNING") { $cleanerScore++ }

if ($jumpListOutput -join "`n" -match "WARNING") { $cleanerScore++ }

Write-Host ""
Write-Host "--- Cleaner Activity Score ---" -ForegroundColor White

if ($cleanerScore -ge 4) {

    Write-Host "LIKELY CLEANER ACTIVITY DETECTED ($cleanerScore/5)" -ForegroundColor Red

}
elseif ($cleanerScore -ge 2) {

    Write-Host "SUSPICIOUS SYSTEM CLEANING DETECTED ($cleanerScore/5)" -ForegroundColor Yellow

}
else {

    Write-Host "No major cleaner activity detected ($cleanerScore/5)" -ForegroundColor Green

}

$allLines = @()

$allLines += $exclusionsOutput
$allLines += $threatsOutput
$allLines += $memoryIntegrityOutput
$allLines += $defenderOutput
$allLines += $exploitOutput
$allLines += $prefetchOutput
$allLines += $keyAuthOutput
$allLines += $registryOutput
$allLines += $pahOutput
$allLines += $deletedPrefetchOutput
$allLines += $userAssistOutput
$allLines += $bamOutput
$allLines += $jumpListOutput
$allLines += $deletedMuiCacheOutput

$successCount = ($allLines | Where-Object {
    $_ -match '^SUCCESS'
}).Count

$failureCount = ($allLines | Where-Object {
    $_ -match '^FAILURE'
}).Count

$warningCount = ($allLines | Where-Object {
    $_ -match '^WARNING'
}).Count

$totalChecks = $successCount + $failureCount + $warningCount

if ($totalChecks -gt 0) {
    $rate = [math]::Round(
        ($successCount / $totalChecks) * 100,
        2
    )
}
else {
    $rate = 0
}

if ($rate -ge 90) {
    $color = "Green"
}
elseif ($rate -ge 70) {
    $color = "Yellow"
}
else {
    $color = "Red"
}

$elapsedSeconds = [math]::Round(
    ((Get-Date) - $startTime).TotalSeconds,
    2
)

Write-Host ""
Write-Host "--- Summary ---" -ForegroundColor White
Write-Host "Success Rate: $rate%" -ForegroundColor $color
Write-Host "Successes: $successCount" -ForegroundColor Green
Write-Host "Failures: $failureCount" -ForegroundColor Red
Write-Host "Warnings: $warningCount" -ForegroundColor Yellow
Write-Host "Completed in $elapsedSeconds seconds." -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Blue
# ===================== END SCRIPT =====================
