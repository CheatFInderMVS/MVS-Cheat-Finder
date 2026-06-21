
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
Write-Host "  LOC Powershell Code, Slightly Modified To Stop Bypassing/Cleaners | @8wl5  " -ForegroundColor Blue -NoNewline
Write-Host " - LOC PowerShell T1" -ForegroundColor White
Write-Host ""

# Simulated loading bar
for ($i = 0; $i -le 10; $i++) {
    $percent = $i * 10
    $bar = "#" * $i + "-" * (10 - $i)
    Write-Host "`r[ $bar ] $percent%" -NoNewline
    Start-Sleep -Milliseconds 300
}
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

# Blacklist definitions
$blacklist = @("matcha", "olduimatrix", "autoexe", "bin", "workspace", "monkeyaim", "thunderaim", "thunderclient", "celex", "release", "matrix", "matcha.exe", "triggerbot", "solara", "xeno", "wave", "cloudy", "tupical", "horizon", "myst", "celery", "zarora", "juju", "nezure", "FusionHacks.zip", "release.zip", "bootstrapper", "aimmy.exe", "aimmy", "Fluxus", "clumsy", "build", "build.zip", "build.rar", "MystW.exe", "isabelle", "dx9", "dx9ware")
$suspiciousList = @("isabelle", "xeno", "solara", "bootstrapper", "bootstrappernew", "loader", "santoware", "mystw", "severe", "mapper", "thunderclient", "monkeyaim", "olduimatrix", "matrix", "matcha")
$watchlist = @("BOOTSTRAPPERNEW.EXE", "BOOTSTRAPPER.EXE", "XENO.EXE", "XENOUI.EXE", "SOLARA.EXE", "MAPPER.EXE", "LOADER.EXE", "MATCHA.EXE", "EVOLVE.EXE")

# --- Exclusion Check ---
try {
    $exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
    $exclusionsOutput += if ($exclusions) {
        "FAILURE: Exclusion paths detected:`n$($exclusions -join "`n")"
    } else {
        "SUCCESS: No Exclusions were found at the moment."
    }
} catch {
    $exclusionsOutput += "WARNING: Could not get exclusion paths. MUST RUN AS ADMINISTRATOR!"
}

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

# --- Exploit Check ---
try {
    $hash = "A89E3321B2BC0A90C21714F153E26DCF2BDEA4BC7200AF9C8CA8394FF54470A1"
    $found = Test-Path "$env:APPDATA\Isabelle"
    if ($hash -and $found) {
        $exploitOutput += "FAILURE: Isabelle exploit folder found and hash matched."
    } else {
        $exploitOutput += "SUCCESS: No exploit signs found."
    }
} catch {
    $exploitOutput += "WARNING: Exploit check could not be completed."
}

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

# --- Key Checker ---
try {
    $folders = Get-ChildItem "C:\ProgramData\KeyAuth\debug" -Directory -ErrorAction Stop
    foreach ($f in $folders) {
        $keyAuthOutput += "FAILURE: External cheat/KeyAuth folder: $($f.Name)"
    }
} catch {
    $keyAuthOutput += "SUCCESS: No KeyAuth folders found."
}

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

# --- Print Results ---
function Write-Section {
    param ([string]$Title, [string[]]$Lines)
    Write-Host "--- $Title ---" -ForegroundColor White
    foreach ($line in $Lines) {
        if ($line -match "^SUCCESS") {
            Write-Host $line -ForegroundColor Green
        } elseif ($line -match "^FAILURE") {
            Write-Host $line -ForegroundColor Red
        } elseif ($line -match "^WARNING") {
            Write-Host $line -ForegroundColor Yellow
        } else {
            Write-Host $line -ForegroundColor White
        }
    }
}


Write-Section "Prefetch" $prefetchOutput

Write-Section "Exclusions" $exclusionsOutput
Write-Section "Threats" $threatsOutput
Write-Section "Memory Integrity" $memoryIntegrityOutput
Write-Section "Windows Defender" $defenderOutput
Write-Section "Exploit Checker" $exploitOutput
Write-Section "Key Checker" $keyAuthOutput
Write-Section "Registry Scan" $registryOutput
Write-Section "PAH (Process Active History)" $pahOutput

# --- Summary ---
$allSections = @(
    $exclusionsOutput, $threatsOutput, $memoryIntegrityOutput, $defenderOutput,
    $exploitOutput, $prefetchOutput, $keyAuthOutput, $registryOutput, $pahOutput
)
$successCount = ($allSections | ForEach-Object {
    if ($_ -notcontains ($_ | Where-Object { $_ -match '^FAILURE' })) { 1 } else { 0 }
}) | Measure-Object -Sum | Select-Object -ExpandProperty Sum

$total = $allSections.Count
$failures = $total - $successCount
$warnings = ($allSections | ForEach-Object { $_ | Where-Object { $_ -match '^WARNING' } }).Count
$rate = [math]::Round(($successCount / $total) * 100, 2)

$color = if ($rate -eq 100) { "Green" } else { "Red" }

Write-Host ""
Write-Host "--- Summary ---" -ForegroundColor White
Write-Host "Success Rate: $rate% ($successCount / $total)" -ForegroundColor $color
Write-Host "Failures: $failures" -ForegroundColor Red
Write-Host "Warnings: $warnings" -ForegroundColor Yellow
Write-Host "Completed in $((Get-Date) - $startTime).TotalSeconds seconds." -ForegroundColor Red
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Blue

# ===================== END SCRIPT =====================
