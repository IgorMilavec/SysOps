#Requires -Version 5.1
#Requires -RunAsAdministrator
<#

.DESCRIPTION
 Import root certificates from 

.EXAMPLE

 powershell -ExecutionPolicy ByPass -Noprofile -Noninteractive -File ".\Import-TrustServiceList.ps1" "http://www.mju.gov.si/fileadmin/mju.gov.si/pageuploads/DID/Informacijska_druzba/eIDAS/SI_TL.xml"
 This command will download the official trust service status list for Slovenia.

#>

param(
	[Parameter(Mandatory=$false)]
	[string]$url
)
Set-StrictMode -Version 2.0

$doc = New-Object System.Xml.XmlDocument
$doc.PreserveWhitespace = $true
$doc.Load($url)

$ns = New-Object Xml.XmlNamespaceManager $doc.NameTable
$ns.AddNamespace( "tns", "http://uri.etsi.org/02231/v2#")
$doc.SelectNodes('/tns:TrustServiceStatusList/tns:TrustServiceProviderList/tns:TrustServiceProvider/tns:TSPServices/tns:TSPService/tns:ServiceInformation[tns:ServiceTypeIdentifier = "http://uri.etsi.org/TrstSvc/Svctype/CA/QC" and tns:ServiceStatus = "http://uri.etsi.org/TrstSvc/TrustedList/Svcstatus/granted"]/tns:ServiceDigitalIdentity/tns:DigitalId/tns:X509Certificate', $ns) | Select-Object -ExpandProperty InnerText | Get-Unique | %{
	[System.Security.Cryptography.X509Certificates.X509Certificate2]([System.Convert]::FromBase64String($_)) | 
	?{ $_.Subject -eq $_.Issuer } | ?{ $_.NotAfter -gt (Get-Date)} |
	%{
		Write-Host $_.Subject
		$cerFilePath = Join-Path $env:Temp "$($_.Thumbprint).cer"
		Write-Host $cerFilePath
		Export-Certificate -FilePath $cerFilePath -Cert $_ | Out-Null
		Import-Certificate -FilePath $cerFilePath -CertStoreLocation cert:\LocalMachine\Root | Out-Null
	}
}
