# Firstboot - run ansible rename script (prep for winrm, which is set up after a reboot)
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
param (
  $branch='master',
  $domain='dev'
)
$TimeSpan= New-TimeSpan -Minutes 5
$Trigger= New-ScheduledTaskTrigger -AtStartup -RandomDelay $TimeSpan
$User= "NT AUTHORITY\SYSTEM"
$Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-Command C:\temp\powershell-scripts-$branch\win102016\secondboot.ps1 -branch $branch"
Register-ScheduledTask -TaskName "secondboot" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force
Unregister-ScheduledTask -TaskName "firstboot" -Confirm:$false
PowerShell.exe -Command "C:\temp\powershell-scripts-$branch\win102016\rename-and-localadminfix-win2016.ps1 -newComputerName $env:computername -newNVDomain $domain -y"
