
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$needsReboot = $True

# Stop and disable services
$services = @(
"Windows Defender",
"Windows Firewall"
)
foreach ($svc in $services) {
    Get-Service "$svc" | Stop-Service -Force -PassThru | Set-Service -StartupType disabled
}

if ($needsReboot) {
    Restart-Computer
}