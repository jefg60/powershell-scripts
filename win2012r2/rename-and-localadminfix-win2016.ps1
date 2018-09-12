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
