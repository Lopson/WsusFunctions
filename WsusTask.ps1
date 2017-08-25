<#
.SYNOPSIS
    Automatically approve updates older than x days and do a cleanup after.
.DESCRIPTION
    This scripts approves updates that are older than a given number of days for
    the update categories and update groups specified. Afterwards, a thorough
    server cleanup is performed, so as to not let old updates linger in the server's
    storage.

    WARNING: Windows 10 GPOs regarding update deferring are ignored when the update
    source is a WSUS server. Therefore, this script is still required if you want to
    implement delays and rings.

    This script depends on the WsusFunctions module, located at:
        C:\Program Files\WindowsPowerShell\Modules\WsusFunctions

.NOTES
    Version:       1.3
    Author:        Gonçalo Lourenço (goncalo.lourenco@gonksys.com)
    Creation Date: 15 August, 2017
    
    1.0: Script creation;
    1.1: Definition updates are approved without delay.
    1.2: Security and Critical updates are also approved without delay.
    1.3: Proper exception handling for exceptions thrown by the Approve-WsusUpdatesForGroup function.
#>

# Import the required modules.
Import-Module WsusFunctions;

# Set update approval parameters.
$wsus = Get-WsusServer;
$nonCriticalDelayInDays = 30;
$wsusGroups = @("Workstations", "Servers");
$wsusNonCriticalCategories = @("FeaturePacks", "ServicePacks", "Updates", "UpdateRollups");
$wsusCriticalCategories = @("CriticalUpdates", "SecurityUpdates", "DefinitionUpdates");
$logFile = "C:\Logs\WsusTask.log";

# Print log header.
$date = Get-Date;
@"
WSUS Task - $date
Server: $($wsus.Name)
Delay in days for Non-Critical Updates: $nonCriticalDelayInDays
Update Groups: $wsusGroups
Update Categories Critical: $wsusCriticalCategories
Update Categories Non-Critical: $wsusNonCriticalCategories
WARNING: Critical patches are approved with no delay.

"@ | Out-File -Encoding utf8 -Append -NoClobber -FilePath $logFile;


# Perform update approval for general and definition updates.
try
{
    Approve-WsusUpdatesForGroup -UpdateGroupList $wsusGroups -UpdateCategories $wsusNonCriticalCategories -WsusServer $wsus `
        -UpdateDelay $nonCriticalDelayInDays 2>&1 | Out-File -Encoding utf8 -Append -NoClobber -FilePath $logFile;
    Approve-WsusUpdatesForGroup -UpdateGroupList $wsusGroups -UpdateCategories $wsusCriticalCategories -WsusServer $wsus `
        -UpdateDelay 0 2>&1 | Out-File -Encoding utf8 -Append -NoClobber -FilePath $logFile;
}
catch
{
    Write-Output "$($_.Exception.Message)`r`n" | Out-File -Encoding utf8 -Append -NoClobber -FilePath $logFile;
}

# Perform a server cleanup
Start-WsusCleanup -WsusServer $wsus 2>&1 | Out-File -Encoding utf8 -Append -NoClobber -FilePath $logFile;

# Print end-of-log footer.
@"

---------------

"@ | Out-File -Encoding utf8 -Append -NoClobber -FilePath $logFile;