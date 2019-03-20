#Requires -Version 3
# powershell -ExecutionPolicy ByPass -Noprofile -Noninteractive -File ".\Notify-FailedLogon.ps1"
param(
	[Parameter(Mandatory=$false)]
	[int]$timeInterval = 60,

	[Parameter(Mandatory=$false)]
	[string]$mailFrom, 

	[Parameter(Mandatory=$false)]
	[string]$mailTo
)
Set-StrictMode -Version 2.0
Import-Module ActiveDirectory -ErrorAction Stop

function Get-KerberosStatusDescription
{
	param (
		[parameter(Mandatory=$true, Position=1)]
		$Number
	)

	switch ($Number)
	{
		0x06 { "Account not found"; break }
		0x12 { "Account disabled, expired or locked out"; break }
		0x17 { "Password has expired"; break }
		0x18 { "Bad password"; break }
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
		-1073741724 { "Account not found"; break }
		-1073741260 { "Account disabled, expired or locked out"; break }
		-1073741711 { "Password has expired"; break }
		-1073741718 { "Bad password"; break }
		-1073741415 { "Account type invalid"; break }
		default { "$_"; break}
	}
}


$Milliseconds = $timeInterval * 60000
[xml]$FilterXML = @"
<QueryList><Query Id="0" Path="Security"><Select Path="Security">
*[System[(EventID=4768 or EventID=4771 or EventID=4776) and TimeCreated[timediff(@SystemTime) &lt;= $Milliseconds]]]
</Select></Query></QueryList>
"@

$domainControllers = @(Get-ADDomainController -Filter * | Select-Object @{Name="FQDN";Expression={($_.Name + '.' + $_.Domain).ToLower()}} | Select-Object -ExpandProperty FQDN)

$events = @($domainControllers | %{
	Write-Host Fetching from $_ ...
	Get-WinEvent -ComputerName $_ -FilterXml $FilterXML -MaxEvents 100 | ?{ $_.KeywordsDisplayNames -contains "Audit Failure" } | %{
		$event = $_

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

		if (-not ($domainControllers -contains $object.MachineName))
		{
			Write-Output $object
		}
	}
})

if ($events.Length -gt 0)
{
	#Filter duplicate events
	if ($mailTo -eq "")
	{
		$events | Sort-Object TimeCreated | Select-Object TimeCreated,UserName,MachineName,StatusDescription | ft
	}
	else
	{
		$events = @(
			$events | 
			Sort-Object TimeCreated | 
			Group-Object -Property UserName,MachineName,StatusDescription | 
			Select-Object -Property @{Name="TimeCreated"; Expression = {$_.Group[0].TimeCreated}},@{Name="UserName"; Expression = {$_.Group[0].UserName}},@{Name="MachineName"; Expression = {$_.Group[0].MachineName}},@{Name="StatusDescription"; Expression = {$_.Group[0].StatusDescription}},Count)

		Write-Host Sending mail...
		$anonymousCredentials = New-Object System.Management.Automation.PSCredential("anonymous",(ConvertTo-SecureString -String "anonymous" -AsPlainText -Force))
		$mailBody = $events | Sort-Object TimeCreated | Select-Object TimeCreated,UserName,MachineName,StatusDescription,Count | ConvertTo-HTML -Head "<style>table{font-family:Verdana;font-size:10pt;}</style>"| Out-String
		Send-MailMessage -From $mailFrom -To ($mailTo -split ",") -Subject "W $($env:ComputerName) AD" -Body $mailBody -BodyAsHTML -SmtpServer "smtp" -Credential $anonymousCredentials
	}
}
