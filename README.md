# Overview

This is a collection of scripts and documentation to have a dedicated DCS Server running on an automated start/stop schedule, but also the possibility to via Discord start and stop it. Once setup, the idea is that everything should work with next to none maintenance. This has been the case for 5 months in Viktor Röd. 

It was written for hosting in AWS but with very little effort could be made to run on any public cloud provider or at home.

Written by and for Viktor Röd, part of NOSIG - https://www.nosig.se/.

# Start-DCS.ps1

This script was written with the goal of having DCS Server automatically start when
the machine itself has booted, or rebooted. I use the Windows Task Scheduler to run it.

Uncomment any/all Write-Log lines to help troubleshooting if stuff breaks. Or add your own.

It does the following:
1) Checks "shared" directory (google drive for example) for mission files
2) Sorts the list of mission files, either on Name or LastModified
3) Takes the mission which ended up on the top of the list and inserts it into DCS serverSettings.lua
4) Sets a server password as we want it changed monthly
5) Starts the DCS updater and authenticates, launches the game

It requires:
- DCS Dedicated Server - https://www.digitalcombatsimulator.com/en/downloads/world/server/
- PowerShell >= 7.1 - https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.1
- AutoIt3 - https://www.autoitscript.com/site/autoit/downloads/

# discordbot.py

An ugly Discord bot implementation that via /slash-commands can start/stop/status AWS EC2 instances.
I'm starting it as a systemd service during boot/startup on a minimal Ubuntu install. See discordbot.service
for ideas.

It requires:
- Python 3.8 - modules boto3, discord, discord-py-slash-command
- ~/.aws/credentials - Authentication credentials for an AWS IAM service account
- ~/.aws/config - see https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
- ./config.yaml for Discord auth creds

# discordbot.service

systemd service script for start the Discord bot during boot, more info inside the file.

# aws-lambda/
For automagic start/stop of AWS EC2 instances using Lambda and CloudWatch. See files for further info.
