# dcs-server-start

This script was written with the goal of having DCS World Server automatically start when
the machine itself has booted, or rebooted. I use the Windows Task Scheduler to run it.
It also logs to file for easier troubleshooting in case something breaks at some point.

It does the following:
  1) Checks "shared" directory (google drive for example) for mission files
  2) Sorts the list of mission files, either on Name or LastModified
  3) Takes the mission which ended up on the top of the list and inserts it into DCS serverSettings.lua
  4) Starts the DCS updater and authenticates, launches the game

It requires:
  - DCS Dedicated Server - https://www.digitalcombatsimulator.com/en/downloads/world/server/
  - PowerShell >= 7.1 - https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.1
  - AutoIt3 - https://www.autoitscript.com/site/autoit/downloads/

All variables and settings that need changing for each setup starts after the functions, 
at the end of the script. Except Send-DiscordMessage, see below.
