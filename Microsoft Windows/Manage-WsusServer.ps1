#Requires -Version 3
# New-ScheduledTask -Action (New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -command .\Manage-WsusServer.ps1' -WorkingDirectory 'C:\Program Files\Scripts') -Principal (New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest) -Trigger (New-ScheduledTaskTrigger -Daily -At '03:00') -Settings (New-ScheduledTaskSettingsSet -Compatibility Win8) | Register-ScheduledTask 'Manage WSUS'
Set-StrictMode -Version 2.0
Import-Module PSWindowsUpdate -ErrorAction Stop

$subscription = (Get-WsusServer).GetSubscription()
$subscription.StartSynchronization()
while ($true) {
	Start-Sleep 30
	$progress = $subscription.GetSynchronizationProgress()
	If ($progress.Phase -eq "NotProcessing") { break; }
	$progress
}

# Approve WSUS updates immediatelly
Get-WsusUpdate -Classification WSUS -Approval Unapproved -Status Needed | Approve-WsusUpdate -Action Install -TargetGroupName 'All Computers'

# Approve needed updates for test computers immediatelly
Get-WsusUpdate -Classification All -Approval Unapproved -Status Needed | Approve-WsusUpdate -Action Install -TargetGroupName 'Guinea pig'

# Approve updates for all computers after 7 days
Get-WsusUpdate -Approval Approved | ?{ $_.Update.ArrivalDate -lt ((Get-Date).AddDays(-7)) } | Approve-WsusUpdate -Action Install -TargetGroupName 'All Computers'

# Cleanup
Get-WsusUpdate -Approval Approved | ?{ $_.Update.IsSuperseded -and $_.ComputersNeedingThisUpdate -eq 0 -and $_.Update.CreationDate -lt (Get-Date).AddMonths(-3)} | Deny-WsusUpdate
Invoke-WsusServerCleanup -DeclineExpiredUpdates -DeclineSupersededUpdates -CleanupObsoleteUpdates -CleanupUnneededContentFiles -CompressUpdates
Get-WsusUpdate -Approval Unapproved -Status InstalledOrNotApplicableOrNoStatus | ?{ $_.Update.CreationDate -lt (Get-Date).AddMonths(-54) } | Deny-WsusUpdate
Get-WsusUpdate -Approval Unapproved -Status InstalledOrNotApplicableOrNoStatus | ?{ $_.Update.Title -match "ARM64" } | Deny-WsusUpdate
Get-WsusUpdate -Approval Unapproved | ?{ $_.Update.IsSuperseded -and $_.ComputersNeedingThisUpdate -eq 0 } | Deny-WsusUpdate
