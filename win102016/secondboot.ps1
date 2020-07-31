# secondboot - run ansible winrm script
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
param ($branch='master')
Unregister-ScheduledTask -TaskName "secondboot" -Confirm:$false
PowerShell.exe -Command "C:\temp\powershell-scripts-$branch\win102016\ansible-bootstrap.ps1 -y"
