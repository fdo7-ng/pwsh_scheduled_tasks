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


$Patch_Wednesday = (Get-PatchTuesday).addDays(1)

$today = Get-Date
$today = $today.AddDays(6)

if ( $today.ToShortDateString() -eq $Patch_Wednesday.ToShortDateString() ){
    Write-Host "Patching Day"
}else{
    $Patch_Wednesday
    $today
}