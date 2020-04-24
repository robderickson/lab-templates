# Modified from https://github.com/rgl/windows-domain-controller-vagrant/blob/master/provision/domain-controller-configure.ps1

# wait until we can access the AD. this is needed to prevent errors like:
#   Unable to find a default server with Active Directory Web Services running.
while ($true) {
    try {
        Get-ADDomain | Out-Null
        break
    } catch {
        Start-Sleep -Seconds 10
    }
}


$adDomain = Get-ADDomain
$domain = $adDomain.DNSRoot
$domainDn = $adDomain.DistinguishedName
$usersAdPath = "CN=Users,$domainDn"
$password = ConvertTo-SecureString -AsPlainText 'Password1!' -Force


# remove the non-routable vagrant nat ip address from dns.
# NB this is needed to prevent the non-routable ip address from
#    being registered in the dns server.
# NB the nat interface is the first dhcp interface of the machine.
$vagrantNatAdapter = Get-NetAdapter -Physical |
    Where-Object {
        $_ | Get-NetIPAddress | Where-Object { $_.PrefixOrigin -eq 'Dhcp' }
    } | Sort-Object -Property Name | Select-Object -First 1

$vagrantNatIpAddress = ($vagrantNatAdapter | Get-NetIPAddress).IPv4Address

# remove the $domain nat ip address resource records from dns.
$vagrantNatAdapter | Set-DnsClient -RegisterThisConnectionsAddress $false

Get-DnsServerResourceRecord -ZoneName $domain -Type 1 |
    Where-Object {$_.RecordData.IPv4Address -eq $vagrantNatIpAddress} |
    Remove-DnsServerResourceRecord -ZoneName $domain -Force

# remove the dc.$domain nat ip address resource record from dns.
$dnsServerSettings = Get-DnsServerSetting -All

$dnsServerSettings.ListeningIPAddress = @(
        $dnsServerSettings.ListeningIPAddress | Where-Object {$_ -ne $vagrantNatIpAddress}
    )
Set-DnsServerSetting $dnsServerSettings
Clear-DnsClientCache

# disable all user accounts, except the ones defined here.
$enabledAccounts = @(
    # NB vagrant only works when this account is enabled.
    'vagrant',
    'Administrator'
)
Get-ADUser -Filter {Enabled -eq $true} | Where-Object {$enabledAccounts -notcontains $_.Name} | Disable-ADAccount


# set the Administrator password.
# NB this is also an Domain Administrator account.
$SetAdministratorPassword = @{
    Identity = "CN=Administrator,$usersAdPath"
    Reset = $true
    NewPassword = $password
}
Set-ADAccountPassword @SetAdministratorPassword

$SetAdministratorUser = @{
    Identity = "CN=Administrator,$usersAdPath"
    PasswordNeverExpires = $true
}
Set-ADUser @SetAdministratorUser    

# Add vagrant to Domain Admins
$AddDomainAdmin = @{
    Identity = 'Domain Admins'
    Members = "CN=vagrant,$usersAdPath"
}
Add-ADGroupMember @AddDomainAdmin

Write-Output 'vagrant Group Membership'
Get-ADPrincipalGroupMembership -Identity 'vagrant' |
    Select-Object Name,DistinguishedName,SID |
    Format-Table -AutoSize | Out-String -Width 2000


Write-Output 'Domain Administrators'
Get-ADGroupMember -Identity 'Domain Admins' |
    Select-Object Name,DistinguishedName,SID |
    Format-Table -AutoSize | Out-String -Width 2000


Write-Output 'Enabled Domain User Accounts'
Get-ADUser -Filter {Enabled -eq $true} |
    Select-Object Name,DistinguishedName,SID |
    Format-Table -AutoSize | Out-String -Width 2000