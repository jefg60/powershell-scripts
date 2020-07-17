# Firstboot - run ansible rename script (prep for winrm)
$trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
Register-ScheduledJob -Trigger $trigger -FilePath C:\scripts\secondboot.ps1 -Name SecondBoot
c:\scripts\rename.ps1 -newComputerName $env:computername -newNVDomain dev -y
Unregister-ScheduledJob -Name FirstBoot
