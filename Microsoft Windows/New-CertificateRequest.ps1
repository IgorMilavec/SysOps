function New-CertificateRequest
{
        param (
             [parameter(Mandatory=$false)]
             [string]$Template,

             [parameter(Mandatory=$true)]
             [string]$SubjectName,

             [parameter(Mandatory=$false)]
             [string[]]$DnsName,

             [parameter(Mandatory=$true)]
             [string]$CertStoreLocation,

             [parameter(Mandatory=$false)]
             [int]$KeyLength = 2048,

             [parameter(Mandatory=$true)]
             [string]$FilePath

        )

    $certStoreItem = (Get-Item $CertStoreLocation)
    if ($certStoreItem.PSDrive.Provider.Name -ne 'Certificate' -or $certStoreItem.PSChildName -ne 'My')
    {
        throw 'Invalid certificate store location was specified.'
    }

    $infFileName = New-TemporaryFile
    $infFileContent = @"
[RequestAttributes]
$(&{if(-not [string]::IsNullOrEmpty($Template)){"CertificateTemplate = $Template"}})

[NewRequest]
Subject = "$SubjectName"
Exportable = true
KeyLength = $KeyLength
RequestType = PKCS10
MachineKeySet = $($certStoreItem.Location -eq 'LocalMachine')
"@

    if ($DnsName -ne $null)
    {
        $infFileContent += @"


[Extensions]
2.5.29.17  = "{text}"
"@


        foreach ($serverName in $DnsName)
        {
            $infFileContent += @"

_continue_ = "dns=$serverName&"
"@
        }
    }

    $infFileContent | Out-File $infFileName
    try
    {
        &certreq.exe -new -f -q "$infFileName" "$FilePath"
    }
    finally
    {
        Remove-Item $infFileName -Force
    }
}
