#Requires -Version 5.1
<#
.DESCRIPTION
 Use the Set-ReceiveLocation cmdlet to modify the settings of existing BizTalk receive locations.

.EXAMPLE
 powershell -ExecutionPolicy ByPass -Noprofile -Noninteractive -Command .\Set-ReceiveLocation.ps1 'Location name' -Status Enabled
#>

param(
	[Parameter(Mandatory=$true)]
	[string]$Name, 

	[Parameter(Mandatory=$false)]
	[string]$Status
)
Set-StrictMode -Version 2.0

$receiveLocation = get-wmiobject msbts_receivelocation -Namespace 'root\MicrosoftBizTalkServer' -Filter "name='$Name'"
if ($receiveLocation -eq $null)
{
	Write-Warning "The operation couldn't be performed because receive location '$Name' couldn't be found."
}

if ($PSBoundParameters.ContainsKey("Status")) {
	switch ($Status) {
		"Enabled" {
			$receiveLocation.Enable() | Out-Null
			Write-Host "Receive location '$Name' has been enabled."
		}
		"Disabled" {
			$receiveLocation.Disable() | Out-Null
			Write-Host "Receive location '$Name' has been disabled."
		}
		default {
			Write-Warning "The operation couldn't be performed because receive location status '$Status' isn't supported."
		}
	}
}
