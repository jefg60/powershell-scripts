# Simple script to configure winrm with self-signed HTTPS certificate.
# Useful for configuring windows with ansible.
# May not work on a partially configured machine. USE WITH CAUTION.
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

# windows Build version the script was written for
$desiredBuild = 14393

# other vars
$logFile = 'C:\log\winrmscript.log'

#check windows version
$detectedBuild = [System.Environment]::OSVersion.Version.Build
if ($detectedBuild -ne $desiredBuild) {
	write-host "This script is for windows Build "$desiredBuild
	write-host "It appears to be running on Build "$detectedBuild
	write-host "Please try a different script"
	Read-Host -Prompt "Press Enter to exit or ctrl-C to return to the shell"
	Exit
} Else {
	Write-host "Build version seems to be in order, here goes..."
}

#Check if we've been here before
if (Test-Path $logFile) {
	write-host "Found a log File at "$logFile" - cowardly refusing to run script twice."
	write-host "Delete "$logFile" if you want to try again"
	Read-Host -Prompt "Press Enter to exit or ctrl-C to return to the shell"
	Exit
} Else {
	Write-Host "no logfile found, continuing"
}

#enable local administrator to configure winrm (otherwise access denied!):
try {
  reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f -ErrorAction Stop
  "Added reg key to enable local admins to configure winrm" | Out-File $logFile -Append
}
catch {
  "ERROR failed to add reg key to HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" | Out-File $logFile -Append
}

# rename and set fqdn
Rename-Computer -NewName $newComputerName
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name "NV Domain" -Value $newNVDomain
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name SyncDomainWithMembership -Value 0
Read-Host -Prompt "Press Enter to reboot or ctrl-C to return to the shell"
Restart-Computer

#ansible user - remove first 
remove-localuser -Name ansible
$password = Read-Host -AsSecureString
New-localuser -Name ansible -Password $password
Add-LocalGroupMember -Group Administrators -Member ansible

# remove HTTP listener and create an HTTPS one
Get-ChildItem -Path WSMan:\localhost\Listener | Where-Object { $_.Keys -contains "Transport=HTTP" } | Remove-Item -Recurse -Force
$fqdn=[System.Net.Dns]::GetHostByName($env:computerName).HostName
$certificateforwinrm=New-SelfSignedCertificate -DnsName $fqdn -CertStoreLocation Cert:\LocalMachine\My
$mycommand = 'winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="'+$fqdn+'"; CertificateThumbprint="'+$certificateforwinrm.Thumbprint+'"}'
cmd /c $mycommand

# private network profile
set-netconnectionprofile -InterfaceAlias Ethernet -NetworkCategory Private
New-NetFirewallRule -DisplayName 'WinRM HTTPS' -Profile @('Domain', 'Private') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('5986')

