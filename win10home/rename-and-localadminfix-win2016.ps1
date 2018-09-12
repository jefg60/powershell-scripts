# Simple script to rename computer and set a primary dns suffix
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

# Get vars from script args
$newComputerName = $args[0]
$newNVDomain = $args[1]

if ( ($newComputerName -eq $null) -or ($newNVDomain -eq $null) ){
	write-host "Syntax: "$PSCommandPath" <new computer name> <new primary dns suffix>"
	exit
}
Else {
	write-host "rename this computer to "$newComputerName"."$newNVDomain"?" 
	read-host -Prompt "Press Enter to continue or CTRL-C to exit"
}

# rename and set fqdn
Rename-Computer -NewName $newComputerName
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name "NV Domain" -Value $newNVDomain
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name SyncDomainWithMembership -Value 0

# registry hack to enable local admins to configure winrm (requires restart)
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f

# reboot
Read-Host -Prompt "Press Enter to reboot or ctrl-C to return to the shell"
Restart-Computer
