# WsusFunctions
## A small collection of Powershell functions to interact with WSUS on WS2012+ servers.

This repository contains a few Powershell functions to ease the automation of a few WSUS operations.
There are no set goals for this repository; the idea is to grow this organically along with my professional needs.
If you'd like to request a new function, go ahead and submit an issue with your request in this repo.
This repository is made up of the module itself, the module's manifest, and an example script using the functions belonging to this module.

Ideally, you'd want to install this module so that it's system-wide, allowing an account capable of managing WSUS to use these functions. The recommended location is:

```
%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\Modules
```

The module currently consists of the following functions:
 
### Start-WsusCleanup
All this does is run the WSUS Server cleanup wizard with aggressive cleanup options.

### Approve-WsusUpdatesForGroup
This function will approve all available updates belonging to a given category that are older than a specified number of days.
When coupled with automatic synchronizations, this functions allows you to setup a "fire-and-forget" WSUS with a reasonable degree of safety.

## Notes for Using this Module

In the wild, I use this in conjunction with a scheduled task that invokes these commands.
Such a task has been verified to work when ran as `NT AUTHORITY\SYSTEM`; neither `NT AUTHORITY\LOCAL SERVICE` nor `NT AUTHORITY\NETWORK SERVICE` seem to be capable of running this task, even when adding one of these accounts to the `WSUS Administrators` local group (which is odd, seeing as the WSUS Service is set to run as `NETWORK SERVICE` by default, but maybe this account has trouble getting the module from the System32 folder). Ideally, you should try using a Managed Service Account for both the WSUS service and the task (MSA must be in the local group `WSUS Administrators`).

The scheduled task should have the following parameters (assuming you're using the example script in this repository):
```
Program: %SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe
Arguments: -ExecutionPolicy Bypass -File "C:\Scripts\WsusTask.ps1"
```

The full path is specified for the Powershell executable in order to make sure the version that's native to the OS' architecture is used (32-bits vs 64-bits).

One more note regarding the module and Powershell in general: redirecting output to `$null` is much faster than pipelining to `Out-Null`. The latter one seems to get tangle dup in garbage collection affairs, as seen in [this StackOverflow question](http://stackoverflow.com/questions/5260125/whats-the-better-cleaner-way-to-ignore-output-in-powershell).