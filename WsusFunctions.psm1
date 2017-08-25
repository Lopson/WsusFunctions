<#
.SYNOPSIS
    Maintenance functions for WSUS.
.DESCRIPTION
    This scripts supplies a WSUS administrator with a function to perform a thorough WSUS cleanup.
    It also contains a function to auto-approve updates belonging to given categories that are older
    than a given number of days.
.NOTES
    Version:       2.1
    Author:        Gonçalo Lourenço (goncalo.lourenco@gonksys.com)
    Creation Date: 15 August, 2017
    
    1.0: Initial script development.
    1.1: Start-WSUSCleanup - Gets a local WSUS server first before running the cleanup cmdlet.
    2.0: Approve-WsusUpdatesForGroup - approves updates for given categories instead of excluding
            updates belonging to give categories; UpdateServer must be given as argument; Array
            parameters are now properly validated; $UpdateDelay's value is now validated.
         Start-WSUSCleanup - Takes an UpdateServer as argument.
    2.1: Approve-WsusUpdatesForGroup - Simplified the way that given update groups are validated.

    For Update Classification GUIDs, see:
        https://msdn.microsoft.com/en-us/library/ff357803(v=vs.85).aspx
    These GUIDs should be the same for all WSUSs.
#>

$ApplicationsClassificationGuid = [GUID]("5c9376ab-8ce6-464a-b136-22113dd69801");
$ConnectorsClassificationGuid = [GUID]("434de588-ed14-48f5-8eed-a15e09a991f6");
$CriticalUpdatesClassificationGuid = [GUID]("e6cf1350-c01b-414d-a61f-263d14d133b4");
$DefinitionUpdatesClassificationGuid = [GUID]("e0789628-ce08-4437-be74-2495b842f43b");
$DeveloperKitsClassificationGuid = [GUID]("e140075d-8433-45c3-ad87-e72345b36078");
$DriversClassificationGuid = [GUID]("ebfc1fc5-71a4-4f7b-9aca-3b9a503104a0");
$FeaturePacksClassificationGuid = [GUID]("b54e7d24-7add-428f-8b75-90a396fa584f");
$GuidanceClassificationGuid = [GUID]("9511d615-35b2-47bb-927f-f73d8e9260bb");
$SecurityUpdatesClassificationGuid = [GUID]("0fa1201d-4330-4fa8-8ae9-b877473b6441");
$ServicePacksClassificationGuid = [GUID]("68c5b0a3-d1a6-4553-ae49-01d3a7827828");
$ToolsClassificationGuid = [GUID]("b4832bd8-e735-4761-8daf-37f882276dab");
$UpdateRollupsClassificationGuid = [GUID]("28bc880e-0592-4cbf-8f95-c79b17911d5f");
$UpdatesClassificationGuid = [GUID]("cd5ffd1e-e932-4e3a-bf74-18bf0b1bbd83");
$UpgradesClassificationGuid = [GUID]("3689bdc8-b205-4af4-8d4a-a63924c5e9d5");

Function Start-WsusCleanup
{
    [CmdletBinding(DefaultParameterSetName = "Default")]
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "WSUS server to interact with.",
                   ParameterSetName = "Default", ValueFromPipeline = $True, Position = 0)]
        [Microsoft.UpdateServices.Internal.BaseApi.UpdateServer]$WsusServer
    )

    Invoke-WsusServerCleanup -UpdateServer $WsusServer -CleanupObsoleteComputers -CleanupObsoleteUpdates `
        -CleanupUnneededContentFiles -DeclineExpiredUpdates -DeclineSupersededUpdates;
}

Function Approve-WsusUpdatesForGroup
{
    [CmdletBinding(DefaultParameterSetName = "Default")]
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "List of names of WSUS Update Groups.",
                   ParameterSetName = "Default", Position = 0)]
        [String[]]$UpdateGroupList,

        [Parameter(Mandatory = $True, HelpMessage = "List of categories for which to approve updates.",
                   ParameterSetName = "Default", Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Applications", "Connectors", "CriticalUpdates", "DefinitionUpdates", "DeveloperKits", "Drivers", "FeaturePacks",
                     "Guidance", "SecurityUpdates", "ServicePacks", "Tools", "UpdateRollups", "Updates", "Upgrades")]
        [String[]]$UpdateCategories,
        
        [Parameter(Mandatory = $True, HelpMessage = "WSUS server to interact with.",
                   ParameterSetName = "Default", ValueFromPipeline = $True, Position = 2)]
        [Microsoft.UpdateServices.Internal.BaseApi.UpdateServer]$WsusServer,

        [Parameter(Mandatory = $False, ParameterSetName = "Default", Position = 3)]
        [ValidateRange(0,[Int32]::MaxValue)]
        [Int32]$UpdateDelay = 0
    )

    # Remove any possible duplicate values from the UpdateGroupList and UpdateCategories arguments.
    $UpdateGroupList = $UpdateGroupList | Select-Object -Unique;
    $UpdateCategories = $UpdateCategories | Select-Object -Unique;

    # Validate that all given update groups exist in the given WSUS server.
    foreach($UpdateGroupGiven in $UpdateGroupList)
    {
        try   {Get-WsusComputer -UpdateServer $WsusServer -ComputerTargetGroups $UpdateGroupGiven > $null;}
        catch {throw [System.ArgumentOutOfRangeException] "Update group $UpdateGroupGiven doesn't exist in Update Server $($WsusServer.Name).";}
    }

    # Create the update scope that'll filter out updates from our search.
    $updateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope;

    # Calculate the update delay.
    $currentDate = Get-Date;
    $maxUpdateReleaseDate = $currentDate.AddDays(-$UpdateDelay);
    $updateScope.ToCreationDate = $maxUpdateReleaseDate;

    # Create an ArrayList of classification types to filter the automatic approval.
    $classificationFilterList = New-Object System.Collections.ArrayList($null);
    foreach ($categoryToInclude in $UpdateCategories)
    {
        if ($categoryToInclude -eq "Applications") {$classificationFilterList.Add($ApplicationsClassificationGuid) > $null;}
        if ($categoryToInclude -eq "Connectors") {$classificationFilterList.Add($ConnectorsClassificationGuid) > $null;}
        if ($categoryToInclude -eq "CriticalUpdates") {$classificationFilterList.Add($CriticalUpdatesClassificationGuid) > $null;}
        if ($categoryToInclude -eq "DefinitionUpdates") {$classificationFilterList.Add($DefinitionUpdatesClassificationGuid) > $null;}
        if ($categoryToInclude -eq "DeveloperKits") {$classificationFilterList.Add($DeveloperKitsClassificationGuid) > $null;}
        if ($categoryToInclude -eq "Drivers") {$classificationFilterList.Add($DriversClassificationGuid) > $null;}
        if ($categoryToInclude -eq "FeaturePacks") {$classificationFilterList.Add($FeaturePacksClassificationGuid) > $null;}
        if ($categoryToInclude -eq "Guidance") {$classificationFilterList.Add($GuidanceClassificationGuid) > $null;}
        if ($categoryToInclude -eq "SecurityUpdates") {$classificationFilterList.Add($SecurityUpdatesClassificationGuid) > $null;}
        if ($categoryToInclude -eq "ServicePacks") {$classificationFilterList.Add($ServicePacksClassificationGuid) > $null;}
        if ($categoryToInclude -eq "Tools") {$classificationFilterList.Add($ToolsClassificationGuid) > $null;}
        if ($categoryToInclude -eq "UpdateRollups") {$classificationFilterList.Add($UpdateRollupsClassificationGuid) > $null;}
        if ($categoryToInclude -eq "Updates") {$classificationFilterList.Add($UpdatesClassificationGuid) > $null;}
        if ($categoryToInclude -eq "Upgrades") {$classificationFilterList.Add($UpgradesClassificationGuid) > $null;}
    }
    $updateClassificationCollection = $WsusServer.GetUpdateClassifications() | Where-Object {$classificationFilterList.Contains($_.Id);}
    
    # Define the classifications to approve updates for in the update scope.
    $updateScope.Classifications.Clear();
    $updateScope.Classifications.AddRange($updateClassificationCollection);

    # Computer Groups have unique names in WSUS, updateGroup will always return one result maximum.
    foreach ($updateGroup in $UpdateGroupList)
    {
        $updateGroup = $WsusServer.GetComputerTargetGroups() | Where-Object {$_.Name -eq $updateGroup;}
        $updateList = $WsusServer.GetUpdates($updateScope);
        
        foreach ($update in $updateList)
        {
            # Approve updates that meet the time constraints given as argument.
            # NOTE: We're not declining superseded updates in this function; that should be done by the Cleanup procedure.
            if (-not $update.IsApproved -and -not $update.IsDeclined -and -not $update.IsSuperseded -and $update.IsLatestRevision)
            {
                if ($update.RequiresLicenseAgreementAcceptance) {$update.AcceptLicenseAgreement() > $null;}
                $update.Approve('Install', $updateGroup) > $null;
                Write-Output ("Approving '{0}' with classification '{1}' for update group '{2}'." -f $update.Title, $update.UpdateClassificationTitle, $updateGroup.Name);
            }
        }
    }
}