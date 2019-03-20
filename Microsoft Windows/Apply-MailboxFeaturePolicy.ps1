#Requires -Version 3
# powershell -ExecutionPolicy ByPass -Noprofile -Noninteractive -File ".\Apply-MailboxFeaturePolicy.ps1"
Set-StrictMode -Version 2.0
Import-Module ActiveDirectory -ErrorAction Stop
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction Stop

$exchangeEnabledUsersActiveSync = Get-ADGroupMember -Identity 'Exchange Enabled Users - ActiveSync' |% DistinguishedName
$exchangeEnabledUsersOWA = Get-ADGroupMember -Identity 'Exchange Enabled Users - OWA' |% DistinguishedName
Get-CasMailbox -ResultSize Unlimited | %{ Set-CasMailbox $_.Name -ActiveSyncEnabled ($exchangeEnabledUsersActiveSync -Contains $_.DistinguishedName) -OWAEnabled ($exchangeEnabledUsersOWA -Contains $_.DistinguishedName) -PopEnabled $false -ImapEnabled $false }
