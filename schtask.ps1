
$taskParams = @("/Create",
            "/TN", "AutomatedScheduledTask", 
            "/SC", "weekly", 
            "/D", "Sunday", 
            "/ST", "08:00", 
            "/TR", "c:\temp\test.ps1", 
            "/F", #force
            "/RU", "system");

# supply the command arguments and execute  
#schtasks.exe $taskParams
 schtasks.exe @taskParams



 $callParams = @("/Create", 
					"/TN", "schtask_taskName_weekly", 
					"/SC", "weekly", 
					"/D", "SUN", 
					"/ST", "08:00", 
					"/TR", ("powershell.exe -File `"$thisScript`" -ConsoleOutputFile `"$logFile`"" -replace '"', '\"'), 
					"/F", #force
					"/RU", "system") #run under the system account
& "schtasks.exe" $callParams




 $callParams = @("/Create", 
					"/TN", "schtask_taskName_monthly", 
					"/SC", "Monthly", 
					"/M", "*", 
					"/ST", "08:00", 
                    "/MO", @("FIRST","THIRD"),
                    "/D", "SUN",
					"/TR", ("powershell.exe - `"$thisScript`" -ConsoleOutputFile `"$logFile`"" -replace '"', '\"'), 
					"/F", #force
					"/RU", "system") #run under the system account
& "schtasks.exe" $callParams


schtasks /create /tn "My App" /tr "c:\apps\myapp.exe" /sc monthly /mo 1