# Simple script to configure winrm with self-signed HTTPS certificate.
# Useful for configuring windows with ansible. No error checking yet, so
# may not work on a partially configured machine. USE WITH CAUTION.
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
#
# allow TCP port 5986 thru firewall.
New-NetFirewallRule -DisplayName 'WinRM HTTPS' -Profile @('Domain', 'Private') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('5986')
# do initial winrm quickconfig (HTTP only)
winrm quickconfig -quiet

# create a self signed cert for the system hostname and use its thumbprint to add the listener.
$fqdn=[System.Net.Dns]::GetHostByName($env:computerName).HostName
$certificateforwinrm=New-SelfSignedCertificate -DnsName $fqdn -CertStoreLocation Cert:\LocalMachine\My
$mycommand = 'winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="'+$fqdn+'"; CertificateThumbprint="'+$certificateforwinrm.Thumbprint+'"}'
cmd /c $mycommand

# Remove the initial HTTP listener
Get-ChildItem -Path WSMan:\localhost\Listener | Where-Object { $_.Keys -contains "Transport=HTTP" } | Remove-Item -Recurse -Force

# remove its firewall rule
Remove-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)"
