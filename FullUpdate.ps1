<#
.SYNOPSIS
    Automated Windows update script that handles winget, Microsoft Store, and Windows Updates.

.DESCRIPTION
    This script performs comprehensive system updates including winget package manager,
    Microsoft Store apps, and Windows system updates. It includes daily skip checks,
    comprehensive logging, and restore point verification.

.PARAMETER Force
    Bypasses the daily run check and forces the script to execute even if it already
    ran today. Useful for manual execution.

.EXAMPLE
    .\FullUpdate.ps1
    Runs the update process if it hasn't run today.

.EXAMPLE
    .\FullUpdate.ps1 -Force
    Forces the update process to run regardless of daily check.
#>
param (
    [switch]$Force
)

# --- Version ---
$ScriptVersion = "1.1"

# --- Admin Check ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: This script must run with Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

# --- Settings ---
$ErrorActionPreference = "Stop"
$StartTime = Get-Date
$Script:TranscriptStarted = $false
$Script:UpdatesFailed = $false
$Script:SkipProcessing = $false

# --- Helper Functions ---
function Ensure-ModuleAvailable {
    param(
        [string]$ModuleName,
        [string]$Description
    )
    
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "ERROR: $Description module '$ModuleName' is not installed." -ForegroundColor Red
        Write-Host "Please install it using: Install-Module -Name $ModuleName -Force" -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Log-Message {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info',
        [switch]$NoTimestamp
    )
    
    $timestamp = if (-not $NoTimestamp) { "[$(Get-Date -Format 'HH:mm:ss')] " } else { "" }
    $color = @{
        'Info'    = 'Cyan'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
        'Success' = 'Green'
    }[$Level]
    
    Write-Host "$timestamp$Message" -ForegroundColor $color
}

try {
    # --- Daily Skip Check ---
    $StateDir = "C:\Scripts\State"
    if (!(Test-Path $StateDir)) { New-Item -ItemType Directory -Path $StateDir | Out-Null }

    $StateFile = "$StateDir\LastRun.txt"
    $Today = (Get-Date).ToString("dd-MMM-yy")

    if (Test-Path $StateFile) {
        $LastRun = Get-Content $StateFile -ErrorAction SilentlyContinue
        
        # Check if we should skip: Only skip if it ran today AND -Force was NOT used
        if ($LastRun -eq $Today -and -not $Force) {
            Log-Message "Script already ran today. Skipping updates. Use -Force to override." -Level 'Info'
            if (Ensure-ModuleAvailable -ModuleName "BurntToast" -Description "BurntToast") {
                try {
                    Import-Module BurntToast -ErrorAction SilentlyContinue
                    New-BurntToastNotification -Text "Update Script", "Skipped — already ran today ($Today)" -ErrorAction SilentlyContinue | Out-Null
                }
                catch { }
            }
            # Set flag to skip processing but continue to finally block
            $Script:SkipProcessing = $true
        }
        elseif ($Force) {
            Log-Message "Force flag detected. Bypassing daily skip check." -Level 'Info'
        }
    }

    # Update last run date
    try {
        $Today | Out-File $StateFile -Force -ErrorAction Stop
    }
    catch {
        Log-Message "WARNING: Could not update state file: $_" -Level 'Warning'
        $Script:UpdatesFailed = $true
    }

    # Skip remaining processing if daily check passed
    if ($Script:SkipProcessing) {
        Write-Host "\nNo updates performed." -ForegroundColor Gray
        throw "Daily skip check - skipping updates"
    }

    # --- Logging Setup ---
    $LogDir = "C:\Scripts\Logs"
    if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

    # Delete logs older than 30 days
    Get-ChildItem $LogDir -File |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
        Remove-Item -Force

    $Date = Get-Date -Format "dd-MMM-yy"
    $LogFile = "$LogDir\UpdateLog-$Date.txt"

    try {
        Start-Transcript -Path $LogFile -Append -ErrorAction SilentlyContinue | Out-Null
        $Script:TranscriptStarted = $true
    }
    catch {
        Write-Host "WARNING: Could not start transcript. Continuing without logging to file." -ForegroundColor Yellow
    }

    # --- Begin Update Process ---
    Write-Host "Starting update process on $Today"
    $Summary = @()


    # --- Winget Updates ---
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Running winget updates..." -ForegroundColor Cyan
    $Summary += "Winget updates started at $(Get-Date -Format 'HH:mm:ss')"
    
    try {
        winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --include-unknown
        if ($LASTEXITCODE -ne 0) {
            Write-Host "WARNING: Winget returned exit code $LASTEXITCODE" -ForegroundColor Yellow
            $Summary += "Winget updates completed with warnings (exit code: $LASTEXITCODE)"
            $Script:UpdatesFailed = $true
        } else {
            $Summary += "Winget updates completed successfully"
        }
    }
    catch {
        Write-Host "ERROR: Winget update failed: $_" -ForegroundColor Red
        $Summary += "Winget updates FAILED: $_"
        $Script:UpdatesFailed = $true
    }


    # --- Microsoft Store Updates ---
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Running Microsoft Store updates..." -ForegroundColor Cyan
    $Summary += "Store updates started at $(Get-Date -Format 'HH:mm:ss')"
    
    try {
        # Check if store command exists
        $storeCmd = Get-Command store -ErrorAction SilentlyContinue
        if ($null -eq $storeCmd) {
            Write-Host "WARNING: 'store' command not found. Skipping Microsoft Store updates." -ForegroundColor Yellow
            $Summary += "Store updates SKIPPED: 'store' command not available"
        } else {
            store updates --apply
            if ($LASTEXITCODE -ne 0) {
                Write-Host "WARNING: Store updates returned exit code $LASTEXITCODE" -ForegroundColor Yellow
                $Summary += "Store updates completed with warnings (exit code: $LASTEXITCODE)"
                $Script:UpdatesFailed = $true
            } else {
                $Summary += "Store updates completed successfully"
            }
        }
    }
    catch {
        Write-Host "ERROR: Store update failed: $_" -ForegroundColor Red
        $Summary += "Store updates FAILED: $_"
        $Script:UpdatesFailed = $true
    }


    # --- Windows Updates ---
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Running Windows Updates..." -ForegroundColor Cyan
    $Summary += "Windows Update scan started at $(Get-Date -Format 'HH:mm:ss')"
    
    try {
        if (-not (Ensure-ModuleAvailable -ModuleName "PSWindowsUpdate" -Description "PSWindowsUpdate")) {
            Write-Host "ERROR: PSWindowsUpdate module unavailable. Skipping Windows updates." -ForegroundColor Red
            $Summary += "Windows Update installation SKIPPED: PSWindowsUpdate module not available"
            $Script:UpdatesFailed = $true
        } else {
            Import-Module PSWindowsUpdate -ErrorAction Stop
            Get-WindowsUpdate -AcceptAll -Download -ErrorAction SilentlyContinue | Out-Null
            Install-WindowsUpdate -AcceptAll -AutoReboot -ErrorAction SilentlyContinue | Out-Null
            $Summary += "Windows Update installation completed at $(Get-Date -Format 'HH:mm:ss')"
        }
    }
    catch {
        Write-Host "ERROR: Windows Update failed: $_" -ForegroundColor Red
        $Summary += "Windows Update installation FAILED: $_"
        $Script:UpdatesFailed = $true
    }


    # --- Check Restore Point ---
    Log-Message "Checking for restore point created during updates..." -Level 'Info'
    
    try {
        $RestorePoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue | Where-Object { $_.CreationTime -gt $StartTime }
        if ($RestorePoints) {
            Log-Message "Restore point found: $($RestorePoints[0].Description)" -Level 'Success'
            $Summary += "Restore point verified: $($RestorePoints[0].Description)"
        } else {
            Log-Message "No restore point created during the update process." -Level 'Warning'
            $Summary += "Restore point: None created"
        }
    }
    catch {
        Log-Message "Could not verify restore point. Insufficient permissions or restore points disabled." -Level 'Warning'
        $Summary += "Restore point check: Unavailable"
    }

    # --- Check Reboot Status ---
    Log-Message "Checking if system reboot is required..." -Level 'Info'
    try {
        $rebootPending = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\" -Name RebootRequired -ErrorAction SilentlyContinue) -ne $null
        if ($rebootPending) {
            Log-Message "System reboot is REQUIRED to complete updates." -Level 'Warning'
            $Summary += "Reboot Status: REQUIRED"
            $Script:UpdatesFailed = $true
        } else {
            Log-Message "No reboot required." -Level 'Success'
            $Summary += "Reboot Status: Not required"
        }
    }
    catch {
        Log-Message "Could not determine reboot status." -Level 'Warning'
        $Summary += "Reboot Status: Unable to determine"
    }

    # --- Summary Output ---
    Write-Host "`n=== Update Summary ===" -ForegroundColor Cyan
    $Summary | ForEach-Object { Write-Host $_ }
    
    if ($Script:UpdatesFailed) {
        Write-Host "`nStatus: COMPLETED WITH WARNINGS/ERRORS" -ForegroundColor Yellow
    } else {
        Write-Host "`nStatus: COMPLETED SUCCESSFULLY" -ForegroundColor Green
    }
}
catch {
    if ($_.Exception.Message -eq "Daily skip check - skipping updates") {
        # This is expected, not a fatal error
        Write-Host "No further action required." -ForegroundColor Gray
    } else {
        Log-Message "Script encountered an unexpected error: $_" -Level 'Error'
        if (-not (Test-Path Variable:\Summary)) { $Script:Summary = @() }
        $Summary += "FATAL ERROR: $_"
        $Script:UpdatesFailed = $true
    }
}
finally {
    # --- End Logging ---
    if ($Script:TranscriptStarted) {
        try {
            Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Host "WARNING: Could not stop transcript properly." -ForegroundColor Yellow
        }
    }

    # --- Completion Notification ---
    try {
        if (Ensure-ModuleAvailable -ModuleName "BurntToast" -Description "BurntToast") {
            Import-Module BurntToast -ErrorAction SilentlyContinue
            $notificationText = if ($Script:UpdatesFailed) { "Updates completed with warnings" } else { "Updates completed successfully" }
            New-BurntToastNotification -Text "Update Script", "$notificationText on $Today" -ErrorAction SilentlyContinue | Out-Null
        }
    }
    catch {
        Write-Host "WARNING: Could not send completion notification." -ForegroundColor Yellow
    }
}