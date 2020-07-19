#Requires -Version 5.1
<#
.DESCRIPTION
 Use the Set-ReceiveLocation cmdlet to modify the settings of existing BizTalk receive locations.

.EXAMPLE
 powershell -ExecutionPolicy ByPass -Noprofile -Noninteractive -Command .\Set-ReceiveLocation.ps1 'Location name' -Enabled $True
#>

param(
	[Parameter(Mandatory=$true)]
	[string]$Name, 

	[Parameter(Mandatory=$false)]
	[bool]$Enabled
)
Set-StrictMode -Version 2.0

$receiveLocation = get-wmiobject msbts_receivelocation -Namespace 'root\MicrosoftBizTalkServer' -Filter "name='$Name'"
if ($receiveLocation -eq $null)
{
	throw "The operation couldn't be performed because receive location '$Name' couldn't be found."
}

if ($PSBoundParameters.ContainsKey("Enabled")){
	if ($Enabled)
	{
		$receiveLocation.Enable() | Out-Null
	}
	else
	{
		$receiveLocation.Disable() | Out-Null
	}
}
