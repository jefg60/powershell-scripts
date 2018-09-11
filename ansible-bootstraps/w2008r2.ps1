#in cmd.exe:
winrm qc -quiet
sconfig.cmd - 4 remote management
2 - enable powershell.
5 - enable auto updates
6 - install updates
2 - rename computer
3 - add local admin (ansible user)
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name "NV Domain" -Value "lan"
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name SyncDomainWithMembership -Value 0
shutdown -r -t 0
add-windowsfeature WoW64-NetFx2
$url = "https://raw.githubusercontent.com/jborean93/ansible-windows/master/scripts/Upgrade-PowerShell.ps1"
$file = "$env:temp\Upgrade-PowerShell.ps1"
$username = "ansible"
$password = "password"
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
&$file -Version 3.0 -Username $username -Password $password -Verbose



# 2016 version below.
#enable local administrator to configure winrm (otherwise access denied!):
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f

# rename and set fqdn
Rename-Computer -NewName "w2016"
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name "NV Domain" -Value "lan"
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name SyncDomainWithMembership -Value 0
Restart-Computer

#ansible user - remove first? 
#remove-localuser -Name ansible
$password = Read-Host -AsSecureString
New-localuser -Name ansible -Password $password
Add-LocalGroupMember -Group Administrators -Member ansible

Get-ChildItem -Path WSMan:\localhost\Listener | Where-Object { $_.Keys -contains "Transport=HTTP" } | Remove-Item -Recurse -Force
$fqdn=[System.Net.Dns]::GetHostByName($env:computerName).HostName
$certificateforwinrm=New-SelfSignedCertificate -DnsName $fqdn -CertStoreLocation Cert:\LocalMachine\My
$mycommand = 'winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="'+$fqdn+'"; CertificateThumbprint="'+$certificateforwinrm.Thumbprint+'"}'
cmd /c $mycommand

# private network profile
set-netconnectionprofile -InterfaceAlias Ethernet -NetworkCategory Private
New-NetFirewallRule -DisplayName 'WinRM HTTPS' -Profile @('Domain', 'Private') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('5986')

