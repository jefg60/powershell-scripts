# Simple script to configure winrm with self-signed HTTPS certificate.
# Useful for configuring windows with ansible. No error checking yet, so
# may not work on a partially configured machine. USE WITH CAUTION.
# Tested on a windows 10 home box.
#
# Copyright (C) 2020 Jeff Hibberd
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
#
Param(
	[Switch] $y = $false,
	[Switch] $debug = $false
)

$ErrorActionPreference = "Stop"

function datestring {
	param($Message)
	(Get-Date).ToString("yyyy/M/dd hh:mm:ss") + " $Message"
}

#Vars
$logFile = 'C:\log\winrmscript.log'
$fqdn=[System.Net.Dns]::GetHostByName($env:computerName).HostName
if ( -Not $y ) {
	Write-Host "My FQDN appears to be "$fqdn" Press ENTER to continue with this FQDN"
	Write-Host "There is a rename computer script around here somewhere ;)"
	Read-Host
}

#check windows version
$desiredbuild = 17763
$detectedbuild = [System.Environment]::OSVersion.Version.Build
if ( -Not $detectedbuild -ge $desiredbuild) {
	write-host "This script is for windows build "$desiredbuild" or higher"
	write-host "It appears to be running on build "$detectedbuild
	write-host "Please try a different script"
	Read-Host -Prompt "Press Enter to exit or ctrl-C to return to the shell"
	Exit
} Else {
Write-host "Build version seems to be in order, here goes..."
}

#Check if we've been here before
if (Test-Path $logFile) {
	write-host "Found existing log File at "$logFile
} Else {
	Write-Host "no logfile found, creating it"
	New-Item $logFile -Itemtype file -Force
}

#Check that we can adminster winrm (permissions may be wrong)
try {
	winrm enumerate winrm/config/Listener
	datestring -Message "I can enumerate winrm OK" | Out-File $logFile -Encoding ascii -Append
}
Catch {
	Read-Host -Prompt "Error: Can't enumerate winrm properly. check the rename script for clues"
	Exit
}

# do initial winrm quickconfig (HTTP only)
winrm quickconfig -quiet

# remove HTTP listener and create an HTTPS one
Get-ChildItem -Path WSMan:\localhost\Listener | Where-Object { $_.Keys -contains "Transport=HTTP" } | Remove-Item -Recurse -Force
$certificateforwinrm=New-SelfSignedCertificate -DnsName $fqdn -CertStoreLocation Cert:\LocalMachine\My
$mycommand = 'winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="'+$fqdn+'"; CertificateThumbprint="'+$certificateforwinrm.Thumbprint+'"}'
if (cmd /c $mycommand) {
	datestring -Message "Created winrm HTTPS listener" | Out-File $logFile -Encoding ascii -Append
}
Else {
	datestring -Message "Error creating HTTPS listener. HINT is winrm accessible to local admins? The computer rename script might help" | Out-File $logFile -Encoding ascii -Append
	Write-Host "ERROR: see "$logFile" for details"
}

# remove its firewall rule
Remove-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)"

# allow TCP port 5986 thru firewall.
set-netconnectionprofile -InterfaceAlias Ethernet -NetworkCategory Private
New-NetFirewallRule -DisplayName 'WinRM HTTPS' -Profile @('Domain', 'Private') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('5986')
Set-NetConnectionProfile -Name Network -NetworkCategory Private
Set-ExecutionPolicy -ExecutionPolicy Restricted -Force
