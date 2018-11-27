# Simple script to re-letter a single cdrom drive
#
# Copyright (C) 2018 Jeff Hibberd
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

# Get-WmiObject -Class Win32_volume -Filter "DriveLetter = 'd:'" |Set-WmiInstance -Arguments @{DriveLetter='Z:'}


# Get vars from script args
$newCdLetter = $args[0]

if ($newCdLetter.length -ne 1 ) {
        write-host "Syntax: "$PSCommandPath" <new cd drive letter>"
	write-host "should be a single letter with no punctiation. E: is wrong. E is the correct format"
        exit
}
Else {
	$newcdletter=$newcdletter+":"
}

$cdDrive = Get-WMIObject -Class Win32_CDROMDrive
$filter = "DriveLetter = '" + $cdDrive.Drive.Substring(0,1) + ":'"
Get-WmiObject -Class Win32_volume -Filter $filter |Set-WmiInstance -Arguments @{DriveLetter=$newCdLetter}
