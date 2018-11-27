$cddrive = Get-WMIObject -Class Win32_CDROMDrive
$filter = "DriveLetter = '" + $cddrive.drive.substring(0,1) + "'"
Get-WmiObject -Class Win32_volume -Filter $filter |Set-WmiInstance -Arguments @{DriveLetter='E:'}
