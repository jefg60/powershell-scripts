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
$desiredbuild = 9600
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
## rename and set fqdn
Rename-Computer -NewName "w2012r2"
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name "NV Domain" -Value "lan"
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name SyncDomainWithMembership -Value 0
Restart-Computer

add ansible user using sconfig, the next 2 lines not supported in ps4.0
#New-localuser -Name ansible -Password $password
#Add-LocalGroupMember -Group Administrators -Member ansible

Get-ChildItem -Path WSMan:\localhost\Listener | Where-Object { $_.Keys -contains "Transport=HTTP" } | Remove-Item -Recurse -Force
$fqdn=[System.Net.Dns]::GetHostByName($env:computerName).HostName
$certificateforwinrm=New-SelfSignedCertificate -DnsName $fqdn -CertStoreLocation Cert:\LocalMachine\My
$mycommand = 'winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="'+$fqdn+'"; CertificateThumbprint="'+$certificateforwinrm.Thumbprint+'"}'
cmd /c $mycommand

# private network profile
set-netconnectionprofile -InterfaceAlias Ethernet -NetworkCategory Private
New-NetFirewallRule -DisplayName 'WinRM HTTPS' -Profile @('Domain', 'Private') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('5986')
