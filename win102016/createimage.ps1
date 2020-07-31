# script to set up a firstboot script as scheduled task
param (
  [string]$branch = 'master',
  [string]$domain='dev'
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
