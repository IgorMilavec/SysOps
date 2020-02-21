#Requires -Version 3
#Requires -Modules @{ ModuleName="ActiveDirectory"; ModuleVersion="1.0.0" }
#Requires -RunAsAdministrator
<#

.DESCRIPTION
 Gather the logon failure events from all the domain controllers.

.EXAMPLE

 powershell -ExecutionPolicy ByPass -Noprofile -Noninteractive -Command .\Notify-FailedLogon.ps1 60
 This command will gather the logs and display them on the console.

 powershell -ExecutionPolicy ByPass -Noprofile -Noninteractive -Command .\Notify-FailedLogon.ps1 60 sender@domain.com recipient@domain.com
 This command will gather logs and send a report e-mail. A DNS alias "smtp" must exist that points to a local MX.

.NOTES

 This article might be helpful with setting up appropriate permissions to read the security log:
 https://support.microsoft.com/en-us/help/323076/how-to-set-event-log-security-locally-or-by-using-group-policy

#>

param(
	[Parameter(Position=0, Mandatory=$false)]
	[int]$TimeInterval = 60,

	[Parameter(Position=1, Mandatory=$false)]
	[string]$MailFrom, 

	[Parameter(Position=2, Mandatory=$false)]
	[string[]]$MailTo,

	[Parameter(Mandatory=$false)]
	[string[]]$IgnoreUsers
)
Set-StrictMode -Version 2.0

function Get-KerberosStatusDescription
{
	param (
		[parameter(Mandatory=$true, Position=1)]
		$Number
	)

	switch ($Number)
	{
		0x06 { "Unknown username or bad password"; break }
		0x12 { "Account disabled, expired or locked out"; break }
		0x17 { "Password has expired"; break }
		0x18 { "Unknown username or bad password"; break }
		0x19 { "Additional pre-authentication required"; break }
		0x20 { "Ticket expired"; break }
		default { "$_"; break}
	}
}

function Get-WindowsStatusDescription
{
	param (
		[parameter(Mandatory=$true, Position=1)]
		$Number
	)

	switch ($Number)
	{
		-1073741724 { "Unknown username or bad password"; break }
		-1073741260 { "Account disabled, expired or locked out"; break }
		-1073741711 { "Password has expired"; break }
		-1073741714 { "Unknown username or bad password"; break }
		-1073741718 { "Unknown username or bad password"; break }
		-1073741415 { "Account type invalid"; break }
		default { "$_"; break}
	}
}

function Format-Event
{
	[CmdletBinding()]
	Param (
	        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        	[PSObject[]]$InputObject
	)

process {
	foreach ($event in $InputObject)
	{
		$object = New-Object –TypeName PSObject
		$object | Add-Member –MemberType NoteProperty –Name TimeCreated –Value $event.TimeCreated
		$object | Add-Member –MemberType NoteProperty –Name ControllerName –Value $event.MachineName

		switch ($_.Id)
		{
			4768 {
				$object | Add-Member –MemberType NoteProperty –Name UserName  –Value $event.Properties[0].Value
				$object | Add-Member –MemberType NoteProperty –Name MachineName –Value $event.Properties[9].Value.Replace("::ffff:", "")
				$object | Add-Member –MemberType NoteProperty –Name Status –Value $event.Properties[6].Value
				$object | Add-Member –MemberType NoteProperty –Name StatusDescription –Value (Get-KerberosStatusDescription $event.Properties[6].Value)
				break
			}
			4771 {
				$object | Add-Member –MemberType NoteProperty –Name UserName  –Value $event.Properties[0].Value
				$object | Add-Member –MemberType NoteProperty –Name MachineName –Value $event.Properties[6].Value.Replace("::ffff:", "")
				$object | Add-Member –MemberType NoteProperty –Name Status –Value $event.Properties[4].Value
				$object | Add-Member –MemberType NoteProperty –Name StatusDescription –Value (Get-KerberosStatusDescription $event.Properties[4].Value )
				break
			}
			4776 {
				$object | Add-Member –MemberType NoteProperty –Name UserName  –Value $event.Properties[1].Value
				$object | Add-Member –MemberType NoteProperty –Name MachineName –Value $event.Properties[2].Value
				$object | Add-Member –MemberType NoteProperty –Name Status –Value $event.Properties[3].Value
				$object | Add-Member –MemberType NoteProperty –Name StatusDescription –Value (Get-WindowsStatusDescription $event.Properties[3].Value)
				break
			}
		}

		if ($object.MachineName)
		{
			$nameEntry = Resolve-DnsName $object.MachineName -ErrorAction SilentlyContinue
			if ($nameEntry)
			{
				if (Get-Member -inputobject $nameEntry -name "NameHost" -Membertype Properties)
				{
					$object.MachineName = $nameEntry.NameHost
				}
				else
				{
					$object.MachineName = @($nameEntry.Name)[0]
				}
			}
		}

		Write-Output $object
	}
}
}

$endTime = Get-Date
$startTime = $endTime.AddMinutes(-$TimeInterval)
$filter = @{
	ProviderName="Microsoft-Windows-Security-Auditing";
	LogName="Security”;
	ID=4768,4771,4776;
	Keywords=4503599627370496; # Audit Failure
	StartTime=$startTime;
	EndTime=$endTime
}

$domainControllers = @(Get-ADDomainController -Filter * | Select-Object @{Name="FQDN";Expression={($_.Name + '.' + $_.Domain).ToLower()}} | Select-Object -ExpandProperty FQDN)

$gatherErrors = @()
$events = @($domainControllers | %{
		$controllerName = $_
		Write-Host Fetching from $_ ...
		try
		{
			Get-WinEvent -ComputerName $_ -FilterHashtable $filter -MaxEvents 1000 -ErrorAction Stop | ?{ $_.KeywordsDisplayNames -contains "Audit Failure" } | Format-Event
		}
		catch
		{
			if ($_.CategoryInfo.Category -ne [System.Management.Automation.ErrorCategory]::ObjectNotFound)
			{
				Write-Warning $_
				$gatherErrors += Select-Object -InputObject $_ -Property @{Name="ControllerName"; Expression = {$controllerName}},@{Name="Status"; Expression = {$_.Exception.Message}}
			}
		}
	} | 
	?{ -not ($IgnoreUsers -contains $_.UserName) }
)

if ($MailTo -eq $null)
{
	$events | 
		Sort-Object TimeCreated | 
		Select-Object TimeCreated,UserName,MachineName,StatusDescription | 
		Format-Table -AutoSize
}
else
{
	$mailBody = $null

	if ($gatherErrors.Length -gt 0)
	{
		$mailBody += $gatherErrors |
			Sort-Object ControllerName |
			Select-Object -Property @{Name="Controller name"; Expression = {$_.ControllerName}},Status |
			ConvertTo-HTML -Fragment -PreContent "<p style='color: red'>Failed to gather logs from:</p>" | 
			Out-String
	}

	if ($events.Length -gt 0)
	{
		$mailBody += $events | 
			Group-Object -Property UserName,MachineName,StatusDescription | 
			Select-Object -Property @{Name="User name"; Expression = {$_.Group[0].UserName}},@{Name="Computer name"; Expression = {$_.Group[0].MachineName}},@{Name="Status"; Expression = {$_.Group[0].StatusDescription}},Count |
			Sort-Object Count -Descending |
			ConvertTo-HTML -Fragment -PreContent "<p>List of failed logon attempts between $(Get-Date $startTime -Format "HH:mm") and $(Get-Date $endTime -Format "HH:mm"):</p>" | 
			Out-String
	}

	if ($mailBody -ne $null)
	{
		Write-Host Sending mail...
		$mailBody = "<html>`n<head>`n<style>p,table {font-family:Verdana;font-size:10pt;} td:nth-child(4) {text-align: right;}</style>`n</head>`n<body>`n$($mailBody)`n</body>`n</html>"
		$anonymousCredentials = New-Object System.Management.Automation.PSCredential("anonymous",(ConvertTo-SecureString -String "anonymous" -AsPlainText -Force))
		Send-MailMessage -From $MailFrom -To $MailTo -Subject "W $((Get-ADDomain).DNSRoot) AD" -Body $mailBody -BodyAsHTML -SmtpServer "smtp" -Credential $anonymousCredentials
	}
}
