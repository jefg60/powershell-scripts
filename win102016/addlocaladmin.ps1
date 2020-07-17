# script to add a local admin user
#
# Copyright (C) 2020 Jeff Hibberd
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
#

Param(
	[string] $adminUserName = 'ansible'
)

$encryptedAdminPassword = Read-Host -AsSecureString -Prompt "admin user password"
$ErrorActionPreference = "Stop"

#remove user first (silently continue if not there)
remove-localuser -Name $adminUserName -ErrorAction SilentlyContinue
try {
	New-localuser -Name $adminUserName -Password $encryptedAdminPassword -ErrorAction Stop
	Add-LocalGroupMember -Group Administrators -Member $adminUserName -ErrorAction Stop
}
Catch {
	write-host "Error adding admin user"
}
