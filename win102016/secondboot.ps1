# secondboot - run ansible winrm script
param ($branch='master')
Unregister-ScheduledTask -TaskName "secondboot" -Confirm:$false
C:\temp\powershell-scripts-$branch\win102016\ansible-bootstrap.ps1 -y
