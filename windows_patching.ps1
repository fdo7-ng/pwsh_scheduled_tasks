[CmdletBinding()]
Param(
  [Parameter(Mandatory=$false)][switch]$setup,
  [Parameter(Mandatory=$true)][String]$time,
  [Parameter(Mandatory=$true)][String]$environment
)
$global:verboseLogFile

# Logger
Function Logger {
    param(
    [Parameter(Mandatory=$true)]
    [String]$message
    )

    $timeStamp = Get-Date -Format "MM-dd-yyyy_hh:mm:ss"

    Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
    Write-Host -ForegroundColor Green " $message"
    $logMessage = "[$timeStamp] $message"
    $logMessage | Out-File -Append -LiteralPath $verboseLogFile
}

function Create-Folder {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        [Parameter(mandatory=$true)]
        [string]$Folder
    )    
    Write-Verbose "Create-Folder Function"
    If(!(Test-Path $Folder))
    {
        New-Item -ItemType Directory -Force -Path $Folder
    }
}

#Function to get Patch Tuesday
function Get-PatchTuesday
{ 
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1,
        HelpMessage = 'Please enter a valid month as a number (1 for Jan, 12 for Dec).')]
        [ValidateSet(1,2,3,4,5,6,7,8,9,10,11,12)]
        [string]$Month=$(Get-Date).Month,
         
        [Parameter(Position = 2,
        HelpMessage = 'Please select a valid year in the #### format.')]
        [ValidateSet('2021','2022','2023','2024','2025','2026','2027','2028')]
        [string]$Year=$(Get-Date).Year
    )
 
    [datetime]$firstDayOfTheMonth = (-join ($Month,'/1/',$Year))
    [System.Object]$monthLength = 0..31
    [System.Collections.ArrayList]$tuesdayDates = @()
    
    foreach ($day in $monthLength) {
        [datetime]$loopDay = $firstDayOfTheMonth.AddDays($day)
        if ($loopDay.DayOfWeek -eq 'Tuesday') {
            $tuesdayDates.Add($loopDay) | Out-Null
        }
    }
    
    $tuesdayDates | Select-Object -Index 1
}


$date = $(Get-Date).ToString("yyyyMMdd")
$global:verboseLogFile = "C:\Scripts\logs\windows_patching_" + $date +".log"


# Setup mode: Creates C:\Scripts\windows_patching.ps1
if ($setup) {
    Create-Folder "C:\Scripts"
    Create-Folder "C:\Scripts\logs"
    Logger "Started Script in Setup Mode----- $($MyInvocation.MyCommand)"
    if (Test-Path -Path "C:\Scripts"){
        if (! (Test-Path -Path "C:\Scripts\windows_patching.ps1") ){
            Logger "Script not found. Creating windows_patching.ps1"
            $MyInvocation.MyCommand.ScriptContents | Out-File "C:\Scripts\windows_patching.ps1"
        }else{
            Logger "Script found. Comparing ps1"
            $tempfile = New-TemporaryFile
            $MyInvocation.MyCommand.ScriptContents | Out-File $tempfile.FullName

            if ( Compare-Object -ReferenceObject $(Get-Content "C:\Scripts\windows_patching.ps1") -DifferenceObject $(Get-Content $tempfile.FullName)) {
                Logger "PS1 File Outdated, Replacing"
                $MyInvocation.MyCommand.ScriptContents | Out-File "C:\Scripts\windows_patching.ps1"
            }else{
                Logger "Files Same, Skip"
            }

        }
    }else{
    
        Logger "Creating C:\Scripts\windows_patching.ps1"
        New-Item -Path "C:\Scripts" -Type Directory -Force
        $MyInvocation.MyCommand.ScriptContents | Out-File "C:\Scripts\windows_patching.ps1"
    }

    # Setup Daily Scheduled Task
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "C:\Users\adminuser\Documents\pwsh_scheduled_tasks\windows_patching.ps1 -time $time -environment $environment"
    $trigger =  New-ScheduledTaskTrigger -At 5am -Daily
    Register-ScheduledTask -User 'nt authority\system' -Action $action -Trigger $trigger -TaskName "automated_os_patching" -Force -RunLevel Highest | Out-Null
    Logger "Create/Update automated_os_patching Task"

}else{
    Create-Folder "C:\Scripts\logs"
    # Patching Mode - Runs if Patching Day
    
    Logger "Started Script in Patching Mode----- $($MyInvocation.MyCommand)"
    Logger "Environment $environment"
    # Segregation between non-prod and prod
    if ($environment.tolower() -like "prod") {
        #$patch_day = "Sunday"
        $add_days = "5"
    }else{
        #$patch_day = "Wednesday"
        $add_days = "1"
    } 

    # Identify Patch Day
    $Patch_Day = (Get-PatchTuesday).addDays($add_days)
    $today = Get-Date
    Logger "Patch_Day = $Patch_Day"
    if ( $today.ToShortDateString() -eq $Patch_Day.ToShortDateString() ){
        Logger "Today is $environment Patching Day"
    
        #Initiate Patching
        Install-Module PSWindowsUpdate -Force
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot

    }else{
        Logger "[$Patch_Day] - Patch Day"
        Logger "Not Patching Day, Skip!!!"
    }

}


Logger "Script Ended----- $($MyInvocation.MyCommand)"