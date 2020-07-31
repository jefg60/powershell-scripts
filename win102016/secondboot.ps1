# secondboot - run ansible winrm script
Unregister-ScheduledTask -TaskName "secondboot" -Confirm:$false
c:\scripts\ansible-bootstrap.ps1 -y
