#Requires -Version 5.1
<#
.DESCRIPTION
 Use the Set-SendPort cmdlet to modify the settings of existing BizTalk send ports.

.EXAMPLE
 powershell -ExecutionPolicy ByPass -Noprofile -Noninteractive -Command .\Set-SendPort.ps1 'Port name' -Status Started
#>

param(
	[Parameter(Mandatory=$true)]
	[string]$Name, 

	[Parameter(Mandatory=$false)]
	[string]$Status
)
Set-StrictMode -Version 2.0

$sendPort = get-wmiobject msbts_sendport -Namespace 'root\MicrosoftBizTalkServer' -Filter "name='$Name'"
if ($sendPort -eq $null)
{
	Write-Warning "The operation couldn't be performed because send port '$Name' couldn't be found."
}

if ($PSBoundParameters.ContainsKey("Status")) {
	switch ($Status) {
		"Started" {
			$sendPort.Start() | Out-Null
			Write-Host "Send port '$Name' has been started."
		}
		"Stopped" {
			$sendPort.Stop() | Out-Null
			Write-Host "Send port '$Name' has been stopped."
		}
		default {
			Write-Warning "The operation couldn't be performed because send port status '$Status' isn't supported."
		}
	}
}
