
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$needsReboot = $False

function Set-RegProperty($key, $name, $value, $type="dword") {
    # Forcefully create a property, assuming that $key already exists
    New-ItemProperty "$key" "$name" -PropertyType $type -Value "$value" -Force
}

# Configure Windows Explorer properties
$explorer_key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"

$key = "$explorer_key\Advanced"
New-Item $key -Force
# Show hidden files, folders, and drives
Set-RegProperty $key Hidden 1
# Hide extensions for known file types
Set-RegProperty $key HideFileExt 0
# Hide protected operating system files (Recommended)
Set-RegProperty $key ShowSuperHidden 1

# Disable useless scheduled tasks (find those with schtasks /query)
$tasknames = @(
"Microsoft\Windows\Defrag\ScheduledDefrag",
"Microsoft\Windows Defender\MP Scheduled Scan"
)
foreach ($tn in $tasknames) {
    schtasks /Change /TN "$tn" /disable
}

# Stop and disable useless services. Found with:
# Get-Service | Where-Object {$_.status -eq "running"}
$services = @(
"Windows Update",
"Themes",
"Windows Error Reporting Service"
)
foreach ($svc in $services) {
    Get-Service "$svc" | Stop-Service -Force -PassThru | Set-Service -StartupType disabled
}