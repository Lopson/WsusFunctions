<#
.SYNOPSIS
    Automatically approve updates older than x days and do a cleanup after.
.DESCRIPTION
    This scripts approves updates that are older than a given number of days for
    the update categories and update groups specified. Afterwards, a thorough
    server cleanup is performed, so as to not let old updates to linger in the
    server's storage.

    This script depends on the WsusFunctions module, located at:
        C:\Program Files\WindowsPowerShell\Modules\WsusFunctions
    This module was developed in-house at GONKSYS, S.A.

.NOTES
    Version:       1.0
    Author:        Gonçalo Lourenço (goncalo.lourenco@gonksys.com)
    Creation Date: 01 February, 2017
    
    1.0: Script creation.
    1.1: Redirected STDERR to STDOUT to help in debugging.
#>

# Import the required modules.
Import-Module WsusFunctions;

# Set update approval parameters.
$wsus = Get-WsusServer;
$delayInDays = 30;
$wsusGroups = @("Workstations");
$wsusCategories = @("CriticalUpdates", "DefinitionUpdates", "FeaturePacks", "SecurityUpdates", "ServicePacks", "Updates");
$logFile = "C:\Logs\WsusTask.log";

# Print log header.
$date = Get-Date;
@"
WSUS Task - $date
Server: $($wsus.Name)
Delay in days: $delayInDays
Update Groups: $wsusGroups
Update Categories: $wsusCategories

"@ | Out-File -Encoding utf8 -Append -NoClobber -FilePath $logFile;


# Perform update approval and perform a server cleanup.
Approve-WsusUpdatesForGroup -UpdateGroupList $wsusGroups -UpdateCategories $wsusCategories -WsusServer $wsus `
    -UpdateDelay $delayInDays 2>&1 | Out-File -Encoding utf8 -Append -NoClobber -FilePath $logFile;
Start-WsusCleanup -WsusServer $wsus 2>&1 | Out-File -Encoding utf8 -Append -NoClobber -FilePath $logFile;

# Print end-of-log footer.
@"

---------------

"@ | Out-File -Encoding utf8 -Append -NoClobber -FilePath $logFile;