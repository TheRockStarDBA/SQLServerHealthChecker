# Path to NSSM.exe folder 
Set-Location "C:\nssm-2.24\win64\"

# The path to PowerShell.exe
$Binary = (Get-Command Powershell).Definition

# The necessary arguments, including the path to our script
# change below as per your needs
# -File     : the location to main.ps1
# -listener : AlwaysON Availability Group Listener
# -FilePath : C:\logfiles\SQLServerDBHealthChecker.log
$Arguments = '-ExecutionPolicy Bypass -NoProfile -File "C:\dbhealth-checker\main.ps1" -listener "YourListenerName" -FilePath "C:\logfiles\SQLServerDBHealthChecker.log"'

$description = "SQL Server database health Checker"

# Creating the service 
# Run below 2 commands only. 

.\nssm.exe install SQLServerDbHealthChecker $Binary $Arguments 

.\nssm.exe set SQLServerDbHealthChecker Description $description  

# remove the service if you want to uninstall it 
# .\nssm.exe remove SQLServerDbHealthChecker confirm 
