# Overview

A collection of scripts and documentation to have a dedicated DCS Server running on an automated start/stop schedule, but also the possibility to via Discord start and stop it. Once setup, the idea is that everything should work with next to none maintenance. This has been the case for >5 months in Viktor Röd. 

The repo contents is for hosting in AWS but with very little effort could be made to run on any public cloud provider or at home. I can help out if you have a compelling case :)

Written by, and for Viktor Röd - part of NOSIG. https://www.nosig.se/

Assets:
- 1 AWS EC2 Windows VM. t3.medium 2CPU/4GB RAM. 30GB OS, 200GB game, both SSD GP2. Runs DCS, SRS, LotATC
- 1 AWS EC2 Linux VM. t3.micro (free) 2CPU/1GB RAM. 8GB magnetic. Runs discordbot.py for taking commands via Discord to manually start/stop the VM running DCS
- 2 AWS Lambda functions. Automatic start/stop EC2 VM
- 2 AWS CloudWatch rules. Scheduled triggering of Lambda functions
- AWS IAM Users/Roles/Policies for Discord bot & Lamdba functions
- Contents of this repo

# Start-DCS.ps1

Set to run when the Windows box boots up, it makes sure DCS Server starts with no human interaction. Use the Task Scheduler for example.

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

systemd service script to start the Discord bot during boot, more info inside the file.

# aws-lambda/
Automagic start/stop of AWS EC2 instances using Lambda and CloudWatch. See files for further info.
