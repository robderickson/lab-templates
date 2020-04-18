# Disable Ease of Access keyboard shortcuts
if ($(Get-WindowsEdition -Online).Edition -notmatch "cor") {
    Set-ItemProperty "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506"
    Set-ItemProperty "HKCU:\Control Panel\Accessibility\Keyboard Response" "Flags" "122"
    Set-ItemProperty "HKCU:\Control Panel\Accessibility\ToggleKeys" "Flags" "58"
}

# Disable hibernation
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Power\" -Name "HiberFileSizePercent" -Value 0
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Power\" -Name "HibernateEnabled" -Value 0

# Disable sleep
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
powercfg /change disk-timeout-ac 0
powercfg /change disk-timeout-dc 0
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0

# Disable password expiration for Administrator
Set-LocalUser Administrator -PasswordNeverExpires $true

# Configure PowerShell prompt
$psprofile = @'
Set-Location /

function prompt {
    Write-Host "[$(Get-Date -f 'HH:mm:ss')]" -ForegroundColor Yellow -NoNewline
    " PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
}
'@

New-Item $PROFILE -ItemType File -Force
Set-Content -Path $PROFILE -Value $psprofile