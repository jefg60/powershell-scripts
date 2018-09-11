# Script to configure winrm with self-signed HTTPS certificate.
# Useful for configuring windows with ansible.
# Tested on a non-domain windows 2012 R2 box
# sconfig.cmd was used to create the ansible user.
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

$ErrorActionPreference = "Stop"

# windows Build version the script was written for
$desiredBuild = 9600

# other vars and FQDN check
$logFile = 'C:\log\winrmscript.log'
$fqdn=[System.Net.Dns]::GetHostByName($env:computerName).HostName
Write-Host "My FQDN appears to be "$fqdn" Press ENTER to continue with this FQDN"
Write-Host "There is a rename computer script around here somewhere ;)"
Read-Host

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
	New-Item $logFile -Itemtype file -Force
}

#Check that we can adminster winrm (permissions may be wrong)
try {
  winrm enumerate winrm/config/Listener
  "I can enumerate winrm OK" | Out-File $logFile -Append
}
Catch {
  Read-Host -Prompt "Error: Can't enumerate winrm properly. check the rename script for clues"
  Exit
}

# remove HTTP listener and create an HTTPS one
Get-ChildItem -Path WSMan:\localhost\Listener | Where-Object { $_.Keys -contains "Transport=HTTP" } | Remove-Item -Recurse -Force
Remove-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)"
$certificateforwinrm=New-SelfSignedCertificate -DnsName $fqdn -CertStoreLocation Cert:\LocalMachine\My
$mycommand = 'winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="'+$fqdn+'"; CertificateThumbprint="'+$certificateforwinrm.Thumbprint+'"}'
if (cmd /c $mycommand) {
  "Created winrm HTTPS listener" | Out-File $logFile -Append
}
Else {
  "Error creating HTTPS listener. HINT is winrm accessible to local admins? The computer rename script might help" | Out-File $logFile -Append
  Write-Host "ERROR: see "$logFile" for details"
}

# private network profile
set-netconnectionprofile -InterfaceAlias Ethernet -NetworkCategory Private
New-NetFirewallRule -DisplayName 'WinRM HTTPS' -Profile @('Domain', 'Private') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('5986')

