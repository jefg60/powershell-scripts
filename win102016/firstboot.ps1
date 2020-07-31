# Firstboot - run ansible rename script (prep for winrm, which is set up after a reboot)
param ($branch='master', $domain='dev')
$TimeSpan= New-TimeSpan -Minutes 5
$Trigger= New-ScheduledTaskTrigger -AtStartup -RandomDelay $TimeSpan
$User= "NT AUTHORITY\SYSTEM"
$Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\temp\powershell-scripts-$branch\win102016\secondboot.ps1 -branch $branch"
Register-ScheduledTask -TaskName "secondboot" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force
Unregister-ScheduledTask -TaskName "firstboot" -Confirm:$false
PowerShell.exe -File "C:\temp\powershell-scripts-$branch\win102016\rename-and-localadminfix-win2016.ps1 -newComputerName $env:computername -newNVDomain $domain -y"
