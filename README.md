# WsusFunctions
## A small collection of Powershell functions to interact with WSUS on WS2012+ servers.

This repository contains a few Powershell functions to ease the automation of a few WSUS operations.
There are not set goals for this repository; the idea is to grow this organically along with my professional needs.
If you'd like to request a new function, go ahead and submit an issue with your request in this repo.
This repository is made up of the module itself, the module's manifest, and an example script using the functions belonging to this module.

Ideally, you'd want to install this module so that it's system-wide, allowing the account under which WSUS is running to use these functions, like:

`%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\Modules`

The module currently consists of the following functions:
 
### Start-WsusCleanup
All this does is run the WSUS Server cleanup wizard with aggressive cleanup options.

### Approve-WsusUpdatesForGroup
This function will approve all available updates belonging to a given category that are older than a specified number of days.
When coupled with automatic synchronizations, this functions allows you to setup a "fire-and-forget" WSUS with a reasonable degree of safety.