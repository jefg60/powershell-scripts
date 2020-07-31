# script to set up a firstboot script as scheduled task
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
  [string]$branch = 'master',
  [string]$domain = 'dev'
)
mkdir c:\temp
invoke-webrequest -uri "https://github.com/jefg60/powershell-scripts/archive/$branch.zip" -outfile "c:\temp\powershell-scripts.zip"
expand-archive c:\temp\powershell-scripts.zip -DestinationPath c:\temp
$TimeSpan= New-TimeSpan -Minutes 5
$Trigger= New-ScheduledTaskTrigger -AtStartup -RandomDelay $TimeSpan
$User= "NT AUTHORITY\SYSTEM"
$Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-Command C:\temp\powershell-scripts-$branch\win102016\firstboot.ps1 -branch $branch -domain $domain"
Register-ScheduledTask -TaskName "firstboot" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force
c:\windows\system32\sysprep\sysprep.exe /generalize /shutdown /oobe
