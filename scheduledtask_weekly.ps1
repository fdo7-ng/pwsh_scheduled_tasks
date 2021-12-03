$tmp = New-TemporaryFile


register-scheduledtask -taskname 'terraform_os_patching' `
    -trigger (new-scheduledtasktrigger -once -at (get-date).addminutes(65)) `
    -user 'nt authority\\system' 
    -action (new-scheduledtaskaction -execute 'powershell.exe' -argument '-command \\\"\\\"') `
    -runlevel highest -force

  
  
# Scheduled task to run windows update weekly
   

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' `
    -Argument '-NoProfile -WindowStyle Hidden -command "& { Install-Module PSWindowsUpdate -Force; Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot }"'

$trigger =  New-ScheduledTaskTrigger -At 12am -Weekly -DaysOfWeek Sunday 

Register-ScheduledTask -User 'nt authority\system' -Action $action -Trigger $trigger -TaskPath Terraform -TaskName "AppLog" -Description "Daily dump of Applog" -Force -RunLevel Highest


Get-ScheduledTask -TaskName "AppLog" 











$service = new-object -comobject Schedule.Service
$service.connect()
$taskdefinition = $service.NewTask(0)

$triggers = $taskdefinition.Triggers
$trigger = triggers.Create(5) # I had to try different numbers here, didn't dig through the docs
$trigger.DaysOfWeek = 1 #Thursday
$trigger.WeeksOfMonth = 1 # First week, 2 for second, 6 for third, 8 for forth
$trigger.MonthsOfYear = 4095 # all months
$trigger.RandomDelay = 'PT1H' # 1 hour random delay.