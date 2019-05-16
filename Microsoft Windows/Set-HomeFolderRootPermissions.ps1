#Requires -Version 2
<#

.DESCRIPTION
 Apply default permissions to the folder hosting users' home folder.

.EXAMPLE
 powershell -ExecutionPolicy ByPass -Noprofile -Noninteractive -File ".\Set-HomeFolderRootPermissions.ps1" D:\Users

#>

param(
	[Parameter(Mandatory=$true)]
	[string]$homeFolderRootPath
)
Set-StrictMode -Version 2.0

$defaultAcl = New-Object System.Security.AccessControl.DirectorySecurity
$defaultAcl.SetAccessRuleProtection($true, $true)
$defaultAcl.AddAccessRule(
	(New-Object System.Security.AccessControl.FileSystemAccessRule(
		"Administrators",
		[System.Security.AccessControl.FileSystemRights]"FullControl",
		[System.Security.AccessControl.InheritanceFlags]"None",
		[System.Security.AccessControl.PropagationFlags]"None",
		[System.Security.AccessControl.AccessControlType]::Allow
	))
)
$defaultAcl.AddAccessRule(
	(New-Object System.Security.AccessControl.FileSystemAccessRule(
		"Authenticated Users",
		[System.Security.AccessControl.FileSystemRights]"ReadAndExecute",
		[System.Security.AccessControl.InheritanceFlags]"None",
		[System.Security.AccessControl.PropagationFlags]"None",
		[System.Security.AccessControl.AccessControlType]::Allow
	))
)

Get-Item $homeFolderRootPath | %{ Set-Acl -Path $_.FullName -AclObject $defaultAcl }
