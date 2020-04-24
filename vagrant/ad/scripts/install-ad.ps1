# Borrowed heavily from https://github.com/rgl/windows-domain-controller-vagrant/blob/master/provision/domain-controller.ps1
param(
    [string]$DomainName = 'example.com',
    [securestring]$Password = (ConvertTo-SecureString -String 'Password1!' -AsPlainText -Force)
)

$SetLocalUser = @{
    Name = 'Administrator'
    AccountNeverExpires = $true
    Password = $Password
    PasswordNeverExpires = $true
    UserMayChangePassword = $true
}
Set-LocalUser @SetLocalUser

Disable-LocalUser -Name 'Administrator'

Install-WindowsFeature AD-Domain-Services,RSAT-ADDS-Tools

Import-Module ADDSDeployment

$InstallADDSForest = @{
    InstallDns = $true
    CreateDnsDelegation = $false
    ForestMode = 'WinThreshold'
    DomainMode = 'WinThreshold'
    DomainName = $DomainName
    SafeModeAdministratorPassword = $Password
    NoRebootOnCompletion = $true
    Force = $true
}
Install-ADDSForest @InstallADDSForest