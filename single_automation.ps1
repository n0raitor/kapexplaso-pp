#THis Script was changed by NoSch and implements single host usecases
#Expects structure "Collections\Targets"

Write-Host "Format of the Path to the Case: <YOurPath>\Collections\Target\..."
$path=Read-Host -Prompt "Path to Case Dir (Only up to Collections Parent):"
#$path="D:\_CASES\326-InfoProtect" #Testing
$targetpath="$path\Collections\Targets\"
$pmpath="$path\Collections\PostMortem\"
$timelinepath="$path\Collections\timeline\"
$windowsPath = $path #"E:\CASES\Case_217\Redo"

# Extract the drive letter and convert it to lowercase
$driveLetter = $windowsPath.Substring(0, 2).TrimEnd(':').ToLower()

# Replace the Windows path with the Linux path
$linuxPath = $windowsPath -replace [regex]::Escape($windowsPath.Substring(0, 2)), "/mnt/$driveLetter" -replace '\\', '/'# -replace ' ', '\ '

$l_path=$linuxPath
$l_timelinepath="$l_path/Collections/timeline/"
$l_pmpath="$l_path/Collections/Targets/"

$path = $windowsPath

#Write-Host "Windows Path:" $path
#Write-Host "Linux Path:" $l_path

$top_folder=Split-Path -Path "$path" -Leaf
$timestamp=Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

#Write-Host ""
#Write-Host "Top Folder: " $top_folder
#Write-Host "Timestamp:" $timestamp

$log_prefix=$timestamp+"_CASE_"+$top_folder+"_"
Write-Host "Log Prefix: " $log_prefix


#####################
## Unzipping Target #
#####################

$zipFiles = Get-ChildItem -Path "$targetpath" -Filter "*.zip"
Write-Host "Unziping File: $targetpath$zipFiles"
7z.exe x "$targetpath$zipFiles" -o"$targetpath" -y -bsp1 # Will overwrite every file contained in the zip
Write-Host "Unziping Done"

Write-Host "Processing KAPE"
kape.exe --msource "${targetpath}E" --mdest "${pmpath}" --mflush --module CCMRUAFinder_RecentlyUsedApps,Chainsaw,hayabusa_OfflineEventLogs,DHParser,ObsidianForensics_Hindsight,SRUMDump,NirSoft_BrowsingHistoryView,NirSoft_FullEventLogView_PowerShell-Operational,NirSoft_FullEventLogView_ScheduledTasks,NirSoft_FullEventLogView_Security,NirSoft_FullEventLogView_System,!EZParser,LogParser,LogParser_RDPUsageEvents,NTFSLogTracker,RegRipper,PowerShell_Move-KAPEConsoleHost_history,PowerShell_MFTECmd_J-MFTParsing,PowerShell_Get-DoSvc4n6,EvtxHussar,NirSoft_TurnedOnTimesView,OneDriveExplorer --gui
Write-Host "KAPE Done"

Write-Host "Processing MFT"
MFTECmd.exe -f "${targetpath}E\`$MFT" --body "$timelinepath" --bodyf mftecmd.body --blf --bdl C:
Write-Host "MFT Proc Done"

Write-Host "Processing plaso"
Write-Host $l_timelinepath
Write-Host $l_pmpath
wsl.exe log2timeline.py -z UTC --status_view window --storage-file "${l_timelinepath}timeline.plaso" "${l_pmpath}/E/"
Write-Host "plaso Done"

Write-Host "Processing mactime"
Write-Host $l_timelinepath
Write-Host $l_pmpath
wsl.exe log2timeline.py -z UTC --status_view window --parsers 'mactime' --storage-file "${l_timelinepath}timeline.plaso" "${l_timelinepath}mftecmd.body"
Write-Host "mactime Done"

Write-Host "Processing psort"
Write-Host $l_timelinepath
Write-Host $l_pmpath
wsl.exe sudo psort.py -w "${l_timelinepath}timeline.csv" -o dynamic "${l_timelinepath}timeline.plaso"
Write-Host "psort Done"

#$body = { .\auto_MFTbody.bat $path $log_prefix }
#$mactime = { wsl.exe ./auto_MFTtimeline.sh $l_path }
#$kape = { .\auto_KAPEpostprocessing.bat $path $log_prefix }
#$super = { wsl.exe -u root ./auto_Supertimeline.sh $l_path $log_prefix }

#$job_body = Start-Job -Name body -ScriptBlock $body
#$job_kape = Start-Job -Name kape -ScriptBlock $kape
#Wait-Job -Name body
#$job_mactime = Start-Job -Name mactime -ScriptBlock $mactime
#$job_super = Start-Job -Name super -ScriptBlock $super

