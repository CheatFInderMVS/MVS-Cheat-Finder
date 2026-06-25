# ===================== BEGIN SCRIPT =====================

# Requires Administrator privileges for full accuracy
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host " Please run as Administrator!                       " -ForegroundColor Yellow
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host ""
    Exit
}

# Timer start
$startTime = Get-Date

# Initial UI
Write-Host "   ____ _   _ _____     _  _____   _____ ___ _   _ ____  _____ ____  " -ForegroundColor Green
Write-Host "  / ___| | | | ____|   / \|_   _| |  ___|_ _| \ | |  _ \| ____|  _ \ " -ForegroundColor Green
Write-Host " | |   | |_| |  _|    / _ \ | |   | |_    | ||  \| | | | |  _| | |_) |" -ForegroundColor Green
Write-Host " | |___|  _  | |___  / ___ \| |   |  _|   | || |\  | |_| | |___|  _ < " -ForegroundColor Green
Write-Host "  \____|_| |_|_____/_/   \_\_|   |_|    |___|_| \_|____/|_____|_| \_\" -ForegroundColor Green
Write-Host ""
Write-Host "   Optimized Anti-Cheat Scanner & Cleaner Detector | Enhanced Edition  " -ForegroundColor Blue
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
$bamOutput = @()
$jumpListOutput = @()
$runningProcessesOutput = @()

# Blacklist definitions
$blacklist = @("matcha", "olduimatrix", "autoexe", "workspace", "monkeyaim", "thunderaim", "thunderclient", "celex", "release", "matrix", "matcha.exe", "triggerbot", "solara", "xeno", "wave", "cloudy", "tupical", "horizon", "myst", "celery", "zarora", "juju", "nezure", "FusionHacks.zip", "release.zip", "bootstrapper", "aimmy.exe", "aimmy", "Fluxus", "clumsy", "build", "build.zip", "build.rar", "MystW.exe", "isabelle", "dx9", "dx9ware")
$suspiciousList = @("isabelle", "xeno", "solara", "bootstrapper", "bootstrappernew", "loader", "santoware", "mystw", "severe", "mapper", "thunderclient", "monkeyaim", "olduimatrix", "matrix", "matcha")
$watchlist = @("BOOTSTRAPPERNEW.EXE", "BOOTSTRAPPER.EXE", "XENO.EXE", "XENOUI.EXE", "SOLARA.EXE", "MAPPER.EXE", "LOADER.EXE", "MATCHA.EXE", "EVOLVE.EXE")

# Helper function to check keywords against a string
function Test-IsBlacklisted ($text) {
    if ([string]::IsNullOrEmpty($text)) { return $false }
    foreach ($item in $blacklist) {
        if ($text.ToLower() -contains $item.ToLower() -or $text.ToLower() -like "*$item*") {
            return $true
        }
    }
    return $false
}

# --- Exclusion Check ---
try {
    $exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
    if ($exclusions) {
        $exclusionsOutput += "FAILURE: Exclusion paths detected:"
        foreach ($ex in $exclusions) { $exclusionsOutput += "  -> $ex" }
    } else {
        $exclusionsOutput += "SUCCESS: No Exclusions were found at the moment."
    }
} catch {
    $exclusionsOutput += "WARNING: Could not get exclusion paths."
}
Write-Progress -Activity "CheatFinder Scan" -Status "Exclusions Complete" -PercentComplete 8

# --- Threats Check ---
try {
    Import-Module Defender -ErrorAction SilentlyContinue
    $threats = Get-MpThreatDetection
    $activeThreats = $threats | Where-Object { $_.ThreatStatus -eq "Active" -and $_.QuarantineStatus -ne "Quarantined" }
    if ($activeThreats) {
        foreach ($t in $activeThreats) {
            $threatsOutput += "FAILURE: Threat detected - Name: $($t.ThreatName), Severity: $($t.Severity), Path: $($t.Path)"
        }
    } else {
        $threatsOutput += "SUCCESS: No active threats flagged by Defender."
    }
} catch {
    $threatsOutput += "WARNING: Threat scan could not complete."
}
Write-Progress -Activity "CheatFinder Scan" -Status "Threat Scan Complete" -PercentComplete 16

# --- Running Processes Blacklist ---
try {
    $procs = Get-Process
    $foundBadProc = $false
    foreach ($p in $procs) {
        if (Test-IsBlacklisted $p.ProcessName) {
            $runningProcessesOutput += "FAILURE: Blacklisted active process running: $($p.ProcessName) (PID: $($p.Id))"
            $foundBadProc = $true
        }
    }
    if (-not $foundBadProc) { $runningProcessesOutput += "SUCCESS: No blacklisted active processes running." }
} catch {
    $runningProcessesOutput += "WARNING: Process list scan interrupted."
}
Write-Progress -Activity "CheatFinder Scan" -Status "Process Validation Complete" -PercentComplete 24

# --- Memory Integrity & Blocklist ---
try {
    $miReg = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
    $vbReg = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config" 
    $memOn = Get-ItemPropertyValue -Path $miReg -Name "Enabled" -ErrorAction SilentlyContinue
    $vbOn = $false
    try {
        $vbStatus = Get-ItemPropertyValue -Path $vbReg -Name "VulnerableBlocklistStatus" -ErrorAction SilentlyContinue
        if ($vbStatus -eq 1) { $vbOn = $true }
    } catch {}
    if ($memOn -eq 1 -or $vbOn) {
        $memoryIntegrityOutput += "SUCCESS: Memory integrity is enabled or Vulnerable Blocklist is active."
    } else {
        $memoryIntegrityOutput += "FAILURE: Security Risk! Memory integrity and driver blocklist are both disabled."
    }
} catch {
    $memoryIntegrityOutput += "WARNING: Unable to verify memory integrity state."
}
Write-Progress -Activity "CheatFinder Scan" -Status "Memory Integrity Complete" -PercentComplete 32

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
Write-Progress -Activity "CheatFinder Scan" -Status "Defender Check Complete" -PercentComplete 40

# --- Exploit Folder Check ---
try {
    $found = Test-Path "$env:APPDATA\Isabelle"
    if ($found) { $exploitOutput += "FAILURE: Isabelle cheat folder found in AppData." }
    
    # Generic loop across common directory paths for blacklisted terms
    $scanDirs = @("$env:APPDATA", "$env:LOCALAPPDATA", "C:\ProgramData")
    $flaggedPaths = @()
    foreach ($dir in $scanDirs) {
        if (Test-Path $dir) {
            $subDirs = Get-ChildItem $dir -Directory -ErrorAction SilentlyContinue
            foreach ($sd in $subDirs) {
                if (Test-IsBlacklisted $sd.Name) {
                    $flaggedPaths += "FAILURE: Blacklisted directory footprint found -> $($sd.FullName)"
                }
            }
        }
    }
    if ($flaggedPaths) { $exploitOutput += $flaggedPaths }
    if ($exploitOutput.Count -eq 0) { $exploitOutput += "SUCCESS: No explicit exploit folders or directory names detected." }
} catch {
    $exploitOutput += "WARNING: Exploit directory check could not be fully completed."
}
Write-Progress -Activity "CheatFinder Scan" -Status "Exploit Check Complete" -PercentComplete 48

# --- Prefetch Keyword Check ---
try {
    $now = Get-Date
    $pfFiles = Get-ChildItem "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue
    $foundPf = $false
    foreach ($pf in $pfFiles) {
        $name = $pf.BaseName.ToUpper()
        $lastWrite = $pf.LastWriteTime
        $age = [math]::Round(($now - $lastWrite).TotalHours, 2)
        
        if ($watchlist -contains "$name.EXE" -or (Test-IsBlacklisted $name)) {
            $prefetchOutput += "FAILURE: Blacklisted/Watchlisted prefetch record found: $name | Mod: $age hours ago"
            $foundPf = $true
        }
    }
    if (-not $foundPf) { $prefetchOutput += "SUCCESS: No blacklisted signatures found inside active Prefetch files." }
} catch {
    $prefetchOutput += "WARNING: Could not safely scan prefetch files."
}
Write-Progress -Activity "CheatFinder Scan" -Status "Prefetch Scan Complete" -PercentComplete 56

# --- Deleted Prefetches Check ---
try {
    $prefetchPath = "C:\Windows\Prefetch"
    try {
        $journal = fsutil usn queryjournal C: 2>$null
        if (-not $journal) { $deletedPrefetchOutput += "WARNING: USN Journal unavailable (Possibility of intentional cleaner wipe)." }
    } catch {
        $deletedPrefetchOutput += "WARNING: Unable to poll USN Journal state."
    }

    $pfFiles = Get-ChildItem $prefetchPath -Filter "*.pf" -ErrorAction SilentlyContinue
    if ($pfFiles.Count -lt 40) {
        $deletedPrefetchOutput += "WARNING: Prefetch contains uniquely low counts ($($pfFiles.Count)). Might have been purged."
    }

    $clearedLogs = Get-WinEvent -FilterHashtable @{LogName = 'System'; Id = @(104,1102)} -ErrorAction SilentlyContinue -MaxEvents 1
    if ($clearedLogs) { $deletedPrefetchOutput += "WARNING: Event Log history was cleared recently (ID 104/1102)." }

    $usnDeleted = fsutil usn readjournal C: csv 2>$null | findstr /I "\.pf" | findstr /I "delete"
    $uniqueFiles = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($line in $usnDeleted) {
        if ($line -match '([A-Za-z0-9_\-]+\.PF)') {
            $file = $Matches[1].ToUpper()
            if ($file.Length -gt 8 -and $file -notmatch '^[A-Z0-9]{6,8}\.PF$') {
                $null = $uniqueFiles.Add($file)
            }
        }
    }
    foreach ($file in ($uniqueFiles | Sort-Object)) {
        if (Test-IsBlacklisted $file) {
            $deletedPrefetchOutput += "FAILURE: USN Journal confirms deleted blacklisted prefetch -> $file"
        } else {
            $deletedPrefetchOutput += "WARNING: Deleted Prefetch File Logs: $file"
        }
    }
    if ($deletedPrefetchOutput.Count -eq 0) { $deletedPrefetchOutput += "SUCCESS: Prefetch metrics appear untouched." }
} catch {
    $deletedPrefetchOutput += "WARNING: Could not completely verify USN history."
}
Write-Progress -Activity "CheatFinder Scan" -Status "Deleted Prefetch Cleaners Checked" -PercentComplete 64

# --- Deleted Muicaches Check ---
try {
    $muiPath = "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    $muiKey = Get-Item -Path $muiPath
    $muiCount = $muiKey.ValueCount
    if ($null -eq $muiCount) { $muiCount = ($muiKey.GetValueNames()).Count }
    
    if ($muiCount -lt 30) {
        $deletedMuiCacheOutput += "WARNING: MuiCache registry has suspiciously few entries ($muiCount). Purge suspected!"
    } else {
        $deletedMuiCacheOutput += "SUCCESS: MuiCache data structural integrity clear ($muiCount records)."
    }
} catch {
    $deletedMuiCacheOutput += "WARNING: Missing or inaccessible MuiCache key structure."
}
Write-Progress -Activity "CheatFinder Scan" -Status "MuiCache Complete" -PercentComplete 72

# --- Key Checker ---
try {
    $folders = Get-ChildItem "C:\ProgramData\KeyAuth\debug" -Directory -ErrorAction Stop
    foreach ($f in $folders) {
        $keyAuthOutput += "FAILURE: Active KeyAuth binary footprint: $($f.Name)"
    }
} catch {
    $keyAuthOutput += "SUCCESS: No KeyAuth directories found."
}
Write-Progress -Activity "CheatFinder Scan" -Status "KeyAuth Matrix Evaluated" -PercentComplete 80

# --- UserAssist Check ---
try {
    $userAssistPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
    $count = (Get-ChildItem $userAssistPath -Recurse -ErrorAction SilentlyContinue).Count
    if ($count -lt 5) {
        $userAssistOutput += "WARNING: UserAssist cache seems artificially dropped or cleaned."
    } else {
        $userAssistOutput += "SUCCESS: UserAssist records standard runtime tracking volumes."
    }
} catch {
    $userAssistOutput += "WARNING: UserAssist Hive inaccessible."
}
Write-Progress -Activity "CheatFinder Scan" -Status "UserAssist Validated" -PercentComplete 86

# --- BAM Check ---
try {
    $bamPath = "HKLM:\SYSTEM\CurrentControlSet\Services\bam\State\UserSettings"
    $bamCount = (Get-ChildItem $bamPath -Recurse -ErrorAction SilentlyContinue).Count
    if ($bamCount -lt 5) {
        $bamOutput += "WARNING: BAM operational logs are abnormally low ($bamCount)."
    } else {
        $bamOutput += "SUCCESS: BAM execution metadata volumes standard."
    }
} catch {
    $bamOutput += "WARNING: System structural blocks restricted BAM inspection."
}
Write-Progress -Activity "CheatFinder Scan" -Status "BAM Parsing Finished" -PercentComplete 92

# --- Jump List Check ---
try {
    $autoPath = "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations"
    $customPath = "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations"
    $count = (Get-ChildItem $autoPath -ErrorAction SilentlyContinue).Count + (Get-ChildItem $customPath -ErrorAction SilentlyContinue).Count
    if ($count -lt 5) {
        $jumpListOutput += "WARNING: Jump list metadata history is empty."
    } else {
        $jumpListOutput += "SUCCESS: System jump lists structure healthy."
    }
} catch {
    $jumpListOutput += "WARNING: System Jump list access failed."
}
Write-Progress -Activity "CheatFinder Scan" -Status "JumpLists Complete" -PercentComplete 95

# --- Registry Blacklist Check ---
try {
    $mui = "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    $entries = Get-ItemProperty -Path $mui -ErrorAction SilentlyContinue
    $regFlagged = $false
    foreach ($prop in $entries.PSObject.Properties) {
        $valName = $prop.Name
        if (Test-IsBlacklisted $valName) {
            if ($suspiciousList -contains $valName.ToLower() -or (Test-IsBlacklisted $valName)) {
                $registryOutput += "FAILURE: Blacklisted program traced in MuiCache Registry: $valName"
                $regFlagged = $true
            }
        }
    }
    if (-not $regFlagged) { $registryOutput += "SUCCESS: Registry hives cleared of blacklisted tokens." }
} catch {
    $registryOutput += "WARNING: MuiCache engine tracking errored out."
}
Write-Progress -Activity "CheatFinder Scan" -Status "Registry Scan Complete" -PercentComplete 100

# --- Process Active History Window ---
Start-Job {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    function Show-ProcessActiveHistory {
        $form = New-Object Windows.Forms.Form
        $form.Text = "Process Active History Tracker"
        $form.WindowState = 'Maximized'
        $form.MinimumSize = New-Object Drawing.Size(800, 600)
        $form.StartPosition = "CenterScreen"
        $form.BackColor = [Drawing.Color]::White
        $form.Topmost = $true

        $listBox = New-Object Windows.Forms.ListBox
        $listBox.Dock = 'Fill'
        $listBox.Font = New-Object Drawing.Font("Consolas", 10)
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
                    $msg = "[$stamp] Opened Process: $name"
                    $listBox.Invoke([action]{ $listBox.Items.Add($msg) }) | Out-Null
                }
            }
        })
        $timer.Start()
        $form.Add_Closing({ $timer.Stop(); $timer.Dispose() })
        [void] $form.ShowDialog()
    }
    Show-ProcessActiveHistory
} | Out-Null

Write-Progress -Activity "CheatFinder Scan" -Completed

# --- Output Engine ---
function Write-Section {
    param ([string]$Title, [string[]]$Lines)
    Write-Host "--- $Title ---" -ForegroundColor White
    foreach ($line in $Lines) {
        if ($line -match "^SUCCESS") { Write-Host $line -ForegroundColor Green }
        elseif ($line -match "^FAILURE") { Write-Host $line -ForegroundColor Red }
        elseif ($line -match "^WARNING") { Write-Host $line -ForegroundColor Yellow }
        else { Write-Host $line -ForegroundColor White }
    }
    Write-Host ""
}

Write-Section "Active Processes" $runningProcessesOutput
Write-Section "Jump Lists" $jumpListOutput
Write-Section "BAM History" $bamOutput
Write-Section "UserAssist" $userAssistOutput
Write-Section "Prefetch Logs" $prefetchOutput
Write-Section "Deleted Prefetches" $deletedPrefetchOutput
Write-Section "Deleted Muicaches" $deletedMuiCacheOutput
Write-Section "Exclusions" $exclusionsOutput
Write-Section "Active Threats" $threatsOutput
Write-Section "Memory Integrity" $memoryIntegrityOutput
Write-Section "Windows Defender" $defenderOutput
Write-Section "Exploit Checker" $exploitOutput
Write-Section "Key Checker" $keyAuthOutput
Write-Section "Registry Scan" $registryOutput
Write-Section "PAH (Process Active History)" $pahOutput

# --- Scoring System ---
$cleanerScore = 0
$allOutputsCombined = ($jumpListOutput + $bamOutput + $userAssistOutput + $prefetchOutput + $deletedPrefetchOutput + $deletedMuiCacheOutput + $exclusionsOutput + $threatsOutput + $memoryIntegrityOutput + $defenderOutput + $exploitOutput + $keyAuthOutput + $registryOutput + $runningProcessesOutput)

if ($deletedPrefetchOutput -join "`n" -match "Deleted Prefetch") { $cleanerScore += 2 }
if ($deletedPrefetchOutput -join "`n" -match "USN Journal") { $cleanerScore += 2 }
if ($deletedMuiCacheOutput -join "`n" -match "WARNING") { $cleanerScore++ }
if ($userAssistOutput -join "`n" -match "WARNING") { $cleanerScore++ }
if ($bamOutput -join "`n" -match "WARNING") { $cleanerScore++ }
if ($jumpListOutput -join "`n" -match "WARNING") { $cleanerScore++ }

Write-Host "--- Cleaner Activity Score ---" -ForegroundColor White
if ($cleanerScore -ge 4) { Write-Host "CRITICAL: LIKELY CLEANER ACTIVITY DETECTED ($cleanerScore/5)" -ForegroundColor Red }
elseif ($cleanerScore -ge 2) { Write-Host "SUSPICIOUS SYSTEM CLEANING DETECTED ($cleanerScore/5)" -ForegroundColor Yellow }
else { Write-Host "No system cleanup indicators detected ($cleanerScore/5)." -ForegroundColor Green }

# --- Summary Metrics ---
$successCount = ($allOutputsCombined | Where-Object { $_ -match '^SUCCESS' }).Count
$failureCount = ($allOutputsCombined | Where-Object { $_ -match '^FAILURE' }).Count
$warningCount = ($allOutputsCombined | Where-Object { $_ -match '^WARNING' }).Count
$totalChecks = $successCount + $failureCount + $warningCount

# Replaced the ternary operator with standard IF/ELSE statement
if ($totalChecks -gt 0) {
    $rate = [math]::Round(($successCount / $totalChecks) * 100, 2)
} else {
    $rate = 0
}

# Replaced the nested ternary operator with standard IF/ELSEIF statement
if ($rate -ge 90) {
    $color = "Green"
} elseif ($rate -ge 70) {
    $color = "Yellow"
} else {
    $color = "Red"
}

$elapsedSeconds = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)

Write-Host ""
Write-Host "--- Summary ---" -ForegroundColor White
Write-Host "System Integrity Pass Rate: $rate%" -ForegroundColor $color
Write-Host "System Passes: $successCount" -ForegroundColor Green
Write-Host "Flagged Vulnerabilities/Detections: $failureCount" -ForegroundColor Red
Write-Host "Structural Warnings: $warningCount" -ForegroundColor Yellow
Write-Host "Scan completed execution in $elapsedSeconds seconds." -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Blue
# ===================== END SCRIPT =====================
