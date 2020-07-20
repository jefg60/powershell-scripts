# Firstboot - run ansible rename script (prep for winrm, which is set up after a reboot)
$TimeSpan= New-TimeSpan -Minutes 5
$Trigger= New-ScheduledTaskTrigger -AtStartup -RandomDelay $TimeSpan
$User= "NT AUTHORITY\SYSTEM"
$Action= New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\scripts\secondboot.ps1"
Register-ScheduledTask -TaskName "secondboot" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force
Unregister-ScheduledTask -TaskName "firstboot" -Confirm:$false
c:\scripts\rename.ps1 -newComputerName $env:computername -newNVDomain dev -y
