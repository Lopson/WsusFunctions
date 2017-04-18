# WsusFunctions
## A small collection of Powershell functions to interact with WSUS on WS2012+ servers.

This repository contains a few Powershell functions to ease the automation of a few WSUS operations.
There are no set goals for this repository; the idea is to grow this organically along with my professional needs.
If you'd like to request a new function, go ahead and submit an issue with your request in this repo.
This repository is made up of the module itself, the module's manifest, and an example script using the functions belonging to this module.

Ideally, you'd want to install this module so that it's system-wide, allowing an account capable of managing WSUS to use these functions. The recommended location is:

```
%PROGRAMFILES%\WindowsPowerShell\Modules
```

The module currently consists of the following functions:
 
### Start-WsusCleanup
All this does is run the WSUS Server cleanup wizard with aggressive cleanup options.

### Approve-WsusUpdatesForGroup
This function will approve all available updates belonging to a given category that are older than a specified number of days.
When coupled with automatic synchronizations, this functions allows you to setup a "fire-and-forget" WSUS with a reasonable degree of safety.

## Notes for Using this Module

### WSUS Administrators Permission Problems
If you're an administrator of the machine in which WSUS is running, you won't run into any problems when it comes to invoking the WSUS Cleanup procedure. Likewise, you also won't run into issues when using the `NT AUTHORITY\SYSTEM` account. However, when you try to use an account with less privileges for the Cleanup, such as `NT AUTHORITY\LOCAL SERVICE`, `NT AUTHORITY\NETWORK SERVICE`, or a Group Managed Service Account, you'll be denied access to the cmdlet used in the `Start-WsusCleanup` function even if said account is a member of the local `WSUS Administrators` group. The reason for that is due to an oversight by the engineering team that worked on WS2012 that made it so that members of `WSUS Administrators` are incapable of doing operations that require use of the DCOM belonging to the WSUSCertServer service.

In order to fix this problem, you have to manually add the local group `WSUS Administrators` to the respective DCOM's permissions. To do that, you'll have to do the following procedure:
* Take ownership of the registry folder `HKLM\SOFTWARE\Classes\AppID\{8F5D3447-9CCE-455C-BAEF-55D42420143B}`;
* Open `Dcomcnfg` and go to Component Services, Computers, My Computer, DCOM Config, and modify WSUSCertServer security settings;
* In Launch and Activation permissions, give Local Launch and Local Activation rights to the local `WSUS Administrators` group;
* In Access permissions, give Local Access rights to the local `WSUS Administrators` group.

Afterwards, every account in this group will be able to run the Cleanup procedure.

### Group Managed Service Accounts and WSUS
The ideal way to run WSUS is by using a Group Managed Service Account.
In the case of WSUS, one such account can be used to run the IIS Application Pool belonging to WSUS, as well as an account for running scheduled tasks.
These accounts have multiple distinct advantages which won't be covered in this document.

The most pertinent item when it comes to using a gMSA in the context of WSUS is the scheduled tasks.
Creating a task that runs under a gMSA has to be done via Powershell commands.
The string of commands required to create a task are the following:
``` 
$action = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NoProfile -ExecutionPolicy `"Bypass`" -File `"C:\Scripts\WsusTask.ps1`""
$trigger = New-ScheduledTaskTrigger -At 23:00 -Daily
$principal = New-ScheduledTaskPrincipal -UserID DOMAIN\gMSAAccountName$ -LogonType Password
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -Compatibility Win8 -DontStopIfGoingOnBatteries
Register-ScheduledTask "WSUS Daily Task" –Action $action –Trigger $trigger –Principal $principal -Settings $settings
```

The full path to the powershell executable is explicitly used here in order to guarantee that the 64-bits executable is being used instead of the 32-bits one.
As far as I'm aware, there shouldn't be any bit resolution dependencies, but better be safe than sorry.
Also, don't forget to add read permissions for the gMSA on the folder in which the script of the scheduled task resides and write permissions on the folder in which the task's log file will reside in.

### Out-Null vs $null
One more note regarding the module and Powershell in general: redirecting output to `$null` is much faster than pipelining to `Out-Null`. The latter one seems to get tangle dup in garbage collection affairs, as seen in [this StackOverflow question](http://stackoverflow.com/questions/5260125/whats-the-better-cleaner-way-to-ignore-output-in-powershell).