#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.DESCRIPTION
 Tests reachability and registers a DNS name
.EXAMPLE
 powershell -ExecutionPolicy ByPass -Noprofile -Noninteractive -File ".\Register-GenericAddress.ps1" test ((Get-ADDomain).DNSRoot) 10.1.2.3 10.1.2.4
 This command will test reachability of host "test" in the local domain and register the first available IP address.
#>

param(
	[Parameter(Mandatory=$true, Position=1)]
	[string]$Name,

	[Parameter(Mandatory=$true, Position=2)]
	[string]$ZoneName,

	[Parameter(Mandatory=$true, Position=3)]
	[string]$PrimaryAddress,

	[Parameter(Mandatory=$true, Position=4)]
	[string]$SecondaryAddress
)
Set-StrictMode -Version 2.0
Import-Module DnsServer -ErrorAction Stop

start-transcript "C:\Temp\register.log"

function Set-DnsServerResourceRecordA
{
	param (
		[parameter(Mandatory=$true, Position=1)]
		$InputObject,

		[parameter(Mandatory=$true, Position=2)]
		[string]$ZoneName,

		[parameter(Mandatory=$true, Position=3)]
		[string]$IPv4Address
	)

	$NewInputObject = $InputObject.Clone()
	$NewInputObject.RecordData.IPv4Address = $IPv4Address
	Set-DnsServerResourceRecord -NewInputObject $NewInputObject -OldInputObject $InputObject -ZoneName $ZoneName
}

$dnsRecord = Get-DnsServerResourceRecord -Name $Name -ZoneName $ZoneName -RRType A -ErrorAction Stop

if ((Test-NetConnection "$Name.$ZoneName").PingSucceeded)
{
	Write-Information "The host $Name.$ZoneName is reachable."
}
else
{
	if ((Test-NetConnection $PrimaryAddress).PingSucceeded)
	{
		Write-Information "The address $PrimaryAddress is reachable."
		Set-DnsServerResourceRecordA $dnsRecord $ZoneName $PrimaryAddress
	}
	else
	{
		if ((Test-NetConnection $SecondaryAddress).PingSucceeded)
		{
			Write-Information "The address $SecondaryAddress is reachable."
			Set-DnsServerResourceRecordA $dnsRecord $ZoneName $SecondaryAddress
		}
	}
}
