function Write-Log {
	param (
        [Parameter(Mandatory=$True)]
        [array]$LogLine,
        [Parameter(Mandatory=$True)]
        [string]$Path
	)
    $DateTime = Get-Date -UFormat "%Y-%m-%d %T"
	"[$DateTime] $LogLine" | Out-File $Path -Append
}

$ErrorActionPreference = "Stop"

# Files and dirs
$LogFile = 'C:\Users\Administrator\Desktop\DCSstartup.log'
$GoogleDriveDir = 'C:\Users\Administrator\Google Drive\Missions - Viktor Röd\'
$ConfigFileName = 'C:\Users\Administrator\Saved Games\DCS.server\Config\TESTserverSettings.lua'

Write-Log -LogLine "******************************************" -Path $LogFile
Write-Log -LogLine "Startup script triggered, starting to log." -Path $LogFile

try {
    $MissionFileName = (Get-ChildItem -Path $GoogleDriveDir | Sort-Object -Property Name).Name | Select-Object -First 1

    if ($MissionFileName -match "\.miz$" ) {

        $MissionFullPath = -join($GoogleDriveDir, $MissionFileName)
        $InjectLine = -join("        [1] = ", """$MissionFullPath"",")

        Write-Log -LogLine "Found $MissionFullPath" -Path $LogFile
        
        # Only interested in keeping 1 most-recent backup. Add last x days if needed and rotate
        Write-Log -LogLine "Backing up config" -Path $LogFile
        Copy-Item -Path $ConfigFileName -Destination "$ConfigFileName.bak"

        # Windows fs path in the config file wants double backslashes, like so:
        # [1] = "C:\\Users\\Administrator\\Google Drive\\Missions - Viktor Röd\\This is a mission file!.miz",
        # So we're usign the replace operator. The replace operator's first input is regex, so \ needs escaping.. 
        # Second input isn't. That's why the following can look weird: 
        $InjectLine = $InjectLine -replace "\\", "\\"

        # Update the config file    
        $ConfigFile = Get-Content -Path $ConfigFileName
        $ConfigFile | ForEach-Object {
            if ($_ -match "\[1].*\.miz") { $InjectLine }
            else { $_ }
        } | Set-Content -Path $ConfigFileName
    
        Write-Log -LogLine "Starting mission in $ConfigFileName has been set to $MissionFileName" -Path $LogFile
    }
    else {
        Write-Log -LogLine "Error updating starting mission: The first file in $GoogleDriveDir does not end with .miz. Starting mission in $ConfigFile will not be updated." -Path $LogFile
    }
}
catch {
    Write-Log -LogLine ("Error updating starting mission: {0}" -f $_) -Path $LogFile
}

Write-Log -LogLine "All done" -Path $LogFile
Write-Log -LogLine "******************************************" -Path $LogFile

