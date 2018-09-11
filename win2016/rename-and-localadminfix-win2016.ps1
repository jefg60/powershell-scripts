# set variables here like:
# $newComputerName = 'newname'
# $newNVDomain = 'lan'

if ( ($newComputerName -eq $null) -or ($newNVDomain -eq $null) {
	write-host "Please read script comments and set variables in it first!"
	exit
}

# rename and set fqdn
Rename-Computer -NewName $newComputerName
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name "NV Domain" -Value
$newNVDomain
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters -Name SyncDomainWithMembership -Value 0

# registry hack to enable local admins to configure winrm (requires restart)
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f

# reboot
Read-Host -Prompt "Press Enter to reboot or ctrl-C to return to the shell"
Restart-Computer
