# PCQQ: Win11 24H2 guest SMB access (client side)
# Usage:  irm pc-qq.net/s/guest.ps1 | iex
# Revert: $r=1; irm pc-qq.net/s/guest.ps1 | iex

$url = 'https://pc-qq.net/s/guest.ps1'

# --- self-elevate ---
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    $pre = if ($r) { '$r=1; ' } else { '' }
    Start-Process powershell -Verb RunAs -ArgumentList "-NoExit -ExecutionPolicy Bypass -Command $pre irm $url | iex"
    return
}

$k = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation'

if ($r) {
    Write-Host '[Revert] Restoring secure defaults...' -ForegroundColor Yellow
    Set-SmbClientConfiguration -EnableInsecureGuestLogons $false -RequireSecuritySignature $true -Force
    Remove-ItemProperty $k -Name AllowInsecureGuestAuth -ErrorAction SilentlyContinue
} else {
    Write-Host '[Apply] Enable guest logon / disable signing requirement...' -ForegroundColor Cyan
    Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -RequireSecuritySignature $false -Force
    # Policy key (= gpedit "Enable insecure guest logons"), works on Home too
    if (-not (Test-Path $k)) { New-Item $k | Out-Null }
    Set-ItemProperty $k -Name AllowInsecureGuestAuth -Value 1 -Type DWord
    net use * /delete /y | Out-Null
}

Get-SmbClientConfiguration | Format-List RequireSecuritySignature, EnableInsecureGuestLogons
$p = (Get-ItemProperty $k -ErrorAction SilentlyContinue).AllowInsecureGuestAuth
Write-Host "Policy AllowInsecureGuestAuth = $(if ($null -eq $p) { '(not set)' } else { $p })"

if (-not $r) {
    Write-Host 'OK if: RequireSecuritySignature=False / EnableInsecureGuestLogons=True' -ForegroundColor Green
    Write-Host 'If it reverts: gpedit > Lanman Workstation > Enable insecure guest logons = Enabled'
    Write-Host '               Security Options > MS network client: Digitally sign communications (always) = Disabled'
    Write-Host 'Server side (if 24H2): Set-SmbServerConfiguration -RequireSecuritySignature $false -Force'
}
