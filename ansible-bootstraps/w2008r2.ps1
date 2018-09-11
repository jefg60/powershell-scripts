# Simple script to configure winrm with self-signed HTTPS certificate.
# Useful for configuring windows with ansible. No error checking yet, so
# may not work on a partially configured machine. USE WITH CAUTION.
#
# Copyright (C) 2018 Jeff Hibberd
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#check windows version
$desiredbuild = 7601
$detectedbuild = [System.Environment]::OSVersion.Version.Build
if ($detectedbuild -ne $desiredbuild) {
        write-host "This script is for windows build "$desiredbuild
        write-host "It appears to be running on build "$detectedbuild
        write-host "Please try a different script"
        Read-Host -Prompt "Press Enter to exit or ctrl-C to return to the shell"
        Exit
} Else {
Write-host "Build version seems to be in order, here goes..."
}
##in cmd.exe:
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

