#Requires -Version 7.1

<#
.DESCRIPTION
    
    This script was written with the goal of having DCS Server automatically start when
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
    at the end of the script.
#>

function Write-Log {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [array]$LogLine,
        [Parameter(Mandatory=$True)]
        [string]$Path
    )

    $DateTime = Get-Date -UFormat "%Y-%m-%d %T"
	"[$DateTime] $LogLine" | Out-File $Path -Append

}

function Update-DCSServerConfigStartingMission {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Name","Time")] 
        [string]$SortBy,
        [Parameter(Mandatory=$true)]
        [string]$SharedDriveDir,
        [Parameter(Mandatory=$true)]
        [string]$ConfigFileName
    )

    try {

        switch ($SortBy) {
            Name {  
                $MissionFileName = (Get-ChildItem -Path $SharedDriveDir | 
                                    Sort-Object -Property Name).Name | 
                                    Select-Object -First 1
                Write-Log -LogLine "Sorting mission files by filename and picking the first one." -Path $LogFile
            }
            Time {
                $MissionFileName = (Get-ChildItem -Path $SharedDriveDir | 
                                    Sort-Object -Property LastWriteTime -Descending).Name | 
                                    Select-Object -First 1
                Write-Log -LogLine "Sorting mission files by last modified time and picking the most recent one." -Path $LogFile
            }
        }
    
        if ($MissionFileName -match "\.miz$" ) {
    
            $MissionFullPath = -join($SharedDriveDir, $MissionFileName)
            $InjectLine = -join("        [1] = ", """$MissionFullPath"",")
    
            Write-Log -LogLine "Found $MissionFullPath" -Path $LogFile
            
            # Only interested in keeping 1 most-recent backup. Add last x days if needed and rotate
            Write-Log -LogLine "Backing up config." -Path $LogFile
            Copy-Item -Path $ConfigFileName -Destination "$ConfigFileName.bak"
    
            # Windows fs path in the config file wants double backslashes, like so:
            # [1] = "C:\\Users\\Administrator\\Google Drive\\Missions - Viktor Röd\\This is a mission file!.miz",
            # So we're usign the replace operator. The replace operator's first input is regex, so \ needs escaping.. 
            # Second input isn't. That's why the following can look weird: 
            $InjectLine = $InjectLine -replace "\\", "\\"
    
            # Config file update done here..
            $ConfigFile = (Get-Content -Path $ConfigFileName -Encoding utf8)
            $ConfigFile | ForEach-Object {
                if ($_ -match "\[1].*\.miz") { $InjectLine -replace "`r`n", "`n" }
                else { $_ -replace "`r`n", "`n" }
            } | Set-Content -Path $ConfigFileName -Encoding utf8
        
            Write-Log -LogLine "Starting mission in $ConfigFileName has been set to $MissionFileName" -Path $LogFile
        }
    
        else {
            Write-Log -LogLine "Error updating starting mission: The first file in $SharedDriveDir does not end with .miz. Starting mission in $ConfigFile will not be updated." -Path $LogFile
        }
    }
    catch {
        Write-Log -LogLine ("Error updating starting mission: {0}" -f $_) -Path $LogFile
    }
}

function Start-AU3DCS {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ProgramPath,
        
        [Parameter(Mandatory=$true)]
        [string]$DCSUsername,
       
        [Parameter(Mandatory=$true)]
        [string]$DCSPasswd
    )

    try {
        Import-Module ${env:ProgramFiles(x86)}\AutoIt3\AutoItX\AutoItX.psd1

        Write-Log -LogLine "Ivoking $ProgramPath" -Path $LogFile
        Invoke-AU3Run -Program $ProgramPath
        
        $WindowTitle = 'DCS Login'
        Wait-AU3Win -Title $WindowTitle
        $WindowHandle = Get-AU3WinHandle -Title $WindowTitle
        
        Show-AU3WinActivate -WinHandle $WindowHandle
        
        # Username field
        $ControlHandle1 = Get-AU3ControlHandle -WinHandle $WindowHandle -Control 'Edit1'
        # Password field
        $ControlHandle2 = Get-AU3ControlHandle -WinHandle $WindowHandle -Control 'Edit2'
        # Login button
        $ControlHandle3 = Get-AU3ControlHandle -WinHandle $WindowHandle -Control 'Button3'
    
        Write-Log -LogLine "Authenticating." -Path $LogFile
        Set-AU3ControlText -ControlHandle $ControlHandle1 -NewText $DCSUsername -WinHandle $WindowHandle
        Set-AU3ControlText -ControlHandle $ControlHandle2 -NewText $DCSPasswd -WinHandle $WindowHandle
        Send-AU3ControlKey -ControlHandle $controlHandle3 -Key "{ENTER}" -WinHandle $WindowHandle
    }
    catch {
        Write-Log -LogLine ("AutoIt3: something went wrong: {0}" -f $_) -Path $LogFile
    }
}

$ErrorActionPreference = "Stop"

$LogFile = 'C:\Users\Administrator\Desktop\DCSstartup.log'

Write-Log -LogLine "******************************************" -Path $LogFile
Write-Log -LogLine "Startup script triggered, starting to log." -Path $LogFile
Write-Log -LogLine "PowerShell version is $($PSVersionTable.PSVersion)" -Path $LogFile

$ConfigUpdateSplat = @{
    SortBy = "Name"
    SharedDriveDir = 'C:\Users\Administrator\Google Drive\Missions\'
    ConfigFileName = 'C:\Users\Administrator\Saved Games\DCS.server\Config\serverSettings.lua'
}
Update-DCSServerConfigStartingMission @ConfigUpdateSplat

$AU3Splat = @{
    ProgramPath = 'D:\DCS World Server\bin\DCS_updater.exe'
    DCSUsername = 'user'
    DCSPasswd   = 'pass'
}
Start-AU3DCS @AU3Splat

Write-Log -LogLine "All done!" -Path $LogFile
Write-Log -LogLine "******************************************" -Path $LogFile
