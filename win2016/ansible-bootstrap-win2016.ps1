# Script to configure winrm with self-signed HTTPS certificate.
# Useful for configuring windows with ansible.
# Tested on a non-domain windows 2016 box
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

# other vars and FQDN check
$logFile = 'C:\log\winrmscript.log'
$ansibleUserName = 'ansible'
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

#ansible user - remove first 
remove-localuser -Name $ansibleUserName
try {
  $password = Read-Host -AsSecureString -Prompt "ansible user password:"
  New-localuser -Name $ansibleUserName -Password $password -ErrorAction Stop
  "Added ansible user" | Out-File $logFile -Append
  Add-LocalGroupMember -Group Administrators -Member ansible -ErrorAction Stop
  "Added ansible user to Administrators group" | Out-File $logFile -Append
}
Catch {
  "Error adding ansible user" | Out-File $logFile -Append
}

# remove HTTP listener and create an HTTPS one
Get-ChildItem -Path WSMan:\localhost\Listener | Where-Object { $_.Keys -contains "Transport=HTTP" } | Remove-Item -Recurse -Force
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

