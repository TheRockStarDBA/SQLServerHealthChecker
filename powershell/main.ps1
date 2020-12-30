[cmdletbinding()]
param (
    [Parameter(Mandatory = $true)] [string] $listener,
    [Parameter(Mandatory = $false)] [string] $FilePath = "C:\LogFiles\SQLDbHealthChecker.log"
)

begin {
    
    Write-Output "Importing various Generic functions, Config parameters and modules ..."
    #Import the global generic functions library
    . "$PSScriptRoot\Global_Generic_Functions.ps1"         
 
    # IMport config
    . "$PSScriptRoot\sql_dbhealth_checker_config.ps1"

    #check if dbatools module is imported 
    # make sure that the module is in C:\Program Files\WindowsPowerShell\Modules
    if (-not(Get-Module -ListAvailable -Name dbatools)) {
        Write-LogToJSON -Msg "Module=dbatools not found Aborting" -LogFile $FilePath -LogLevel "ERROR"
        break;
    }       

    function Clean-ErrorMsg {
        param(
            [string]$errorMsg
        )
        # we will strip off quotes so LOG ingestion tool can parse this properly
        [string]$cleanErrorMsg = $errorMsg -replace '"', ""

        return $cleanErrorMsg

    }

    function Invoke-DbHealthProbeIsAlive {
        param(
            [string]$listener
        )
    
    
        try {
            $StopWatch = New-Object System.Diagnostics.Stopwatch
            $StopWatch.Start()
            $results = Invoke-DbaQuery -SqlInstance $listener -QueryTimeout $queryTimeout -Database $databaseName -Query $testReadStoredProc -As DataSet -ErrorVariable sqlerr
            $app_isAlive_elapsed_ms = $StopWatch.ElapsedMilliseconds
            $StopWatch.stop()
            
            if (!$sqlerr) {     

                $msg = "primary_server=$($results.tables[0].rows[0].primary_server), elapsed_ms=$($results.Tables[1].Rows[0].elapsed_ms)"
                Write-LogToJSON -Msg $msg -LogFile $FilePath -LogLevel "INFO" -ExtraArgs @{Check = "IsAlive" ; Result = $checkResult.Success; Name = $($MyInvocation.MyCommand.Name); sql_state = 1; hostmachine = $localhost; app_isAlive_elapsed_ms = $app_isAlive_elapsed_ms }
            }
            else {
                $cleanErroMsg = Clean-ErrorMsg -errorMsg $sqlerr
                Write-LogToJSON -Msg $cleanErroMsg -LogFile $FilePath -LogLevel "ERROR" -ExtraArgs @{Check = "IsAlive" ; Result = $checkResult.Failure; Name = $($MyInvocation.MyCommand.Name); sql_state = 0; hostmachine = $localhost; app_isAlive_elapsed_ms = $app_isAlive_elapsed_ms }
                return @{ExitCode = 0;  Error = $cleanErroMsg; elapsed_ms = $defaultFailureMetric; sql_state = 0; app_isAlive_elapsed_ms = $app_isAlive_elapsed_ms }
            }
            return @{ExitCode = 1; primary_server = $($results.tables[0].rows[0].primary_server); elapsed_ms = $($results.Tables[1].Rows[0].elapsed_ms); sql_state = 1; app_isAlive_elapsed_ms = $app_isAlive_elapsed_ms }
        

        }
        catch {
        
            $cleanErroMsg = Clean-ErrorMsg -errorMsg $connerr
                                                                                       
            Write-LogToJSON -Msg $cleanErroMsg  -LogFile $FilePath -LogLevel "ERROR" -ExtraArgs @{Check = "IsAlive" ; Result = $checkResult.Failure; Name = $($MyInvocation.MyCommand.Name); sql_state = 0; hostmachine = $localhost }
            return @{ExitCode = 0;  Error = $cleanErroMsg; elapsed_ms = $defaultFailureMetric; sql_state = 0; app_isAlive_elapsed_ms = $app_isAlive_elapsed_ms }
        }
    }
 
    function Invoke-DbHealthProbeIsReady {
        param(
            [string]$listener

        )

        try {
        
            $StopWatch = New-Object System.Diagnostics.Stopwatch
            $StopWatch.Start()
            $results = Invoke-DbaQuery -SqlInstance $listener -QueryTimeout $queryTimeout -Database $databaseName -Query $testWriteStoredProc -SqlParameters @{"@servername" = $localhost } -CommandType StoredProcedure -As DataSet -ErrorVariable sqlerr
            $app_isReady_elapsed_ms = $StopWatch.ElapsedMilliseconds
            $StopWatch.stop()
            if (!$sqlerr) {     

                $msg = "primary_server=$($results.tables[0].rows[0].primary_server), inserted_ms=$($results.Tables[1].Rows[0].inserted_ms), app_isReady_elapsed_ms=$app_isReady_elapsed_ms"
                Write-LogToJSON -Msg $msg -LogFile $FilePath -LogLevel "INFO" -ExtraArgs @{Check = "IsReady" ; Result = $checkResult.Success; Name = $($MyInvocation.MyCommand.Name); sql_state = 1; hostmachine = $localhost; app_isReady_elapsed_ms = $app_isReady_elapsed_ms }
            }
            else {
                $cleanErroMsg = Clean-ErrorMsg -errorMsg $sqlerr
                Write-LogToJSON -Msg $cleanErroMsg -LogFile $FilePath -LogLevel "ERROR" -ExtraArgs @{Check = "IsReady" ; Result = $checkResult.Failure; Name = $($MyInvocation.MyCommand.Name); sql_state = 0; hostmachine = $localhost; app_isReady_elapsed_ms = $app_isReady_elapsed_ms }
                return @{ExitCode = 0; sql_state = 0; Error = $cleanErroMsg; inserted_ms = $defaultFailureMetric; app_isReady_elapsed_ms = $app_isReady_elapsed_ms }
            }
            return @{ExitCode = 1; primary_server = $($results.tables[0].rows[0].primary_server); inserted_ms = $($results.Tables[1].Rows[0].inserted_ms); sql_state = 1; app_isReady_elapsed_ms = $app_isReady_elapsed_ms }
        

        }
        catch {
        
            $cleanErroMsg = Clean-ErrorMsg -errorMsg $connerr
                                                                                       
            Write-LogToJSON -Msg $cleanErroMsg  -LogFile $FilePath -LogLevel "ERROR" -ExtraArgs @{Check = "IsReady" ; Result = $checkResult.Failure; Name = $($MyInvocation.MyCommand.Name); sql_state = 0; hostmachine = $localhost; app_isReady_elapsed_ms = $app_isReady_elapsed_ms }
            return @{ExitCode = 0; sql_state = 0; Error = $cleanErroMsg; inserted_ms = $defaultFailureMetric; app_isReady_elapsed_ms = $app_isReady_elapsed_ms }
        }

    } 




}


# main program 
process {
    # infinite loop as this will be run as Win Service.
    while ($true) {
        
        # Log rotation and this will create the log file if it does not exist.
        $logRotate = Rotate-LogFile -Filename $FilePath 
        if($logRotate.ExitCode -eq $false) {
            Write-Output "$($logRotate.ExitMsg)"
            break;
        }

        $Check = Connect-DbaInstance -SqlInstance $listener -ConnectTimeout 1 -WarningVariable connError  -DisableException
  
        if (!$connError) {
            ## Read - IsAlive Probe ....
            $out = Invoke-DbHealthProbeIsAlive -listener $listener
    
            if ($out.ExitCode -eq 1) {
                # here we are getting success, so we can publish metrics to prometheus or Metric tank
                Write-Output "Publishing various IsAlive Probe SUCCESS metrics to Timeseries database"
                # log to log file as well
                $msg = "Performed successful IsAlive Probe - SELECT and published metrics to Timeseries database"
                Write-LogToJSON -Msg $msg -LogFile $FilePath -LogLevel "INFO" -ExtraArgs @{Check = "IsAlive" ; Result = $checkResult.Success; Name = $($MyInvocation.MyCommand.Name); sql_state = $out.sql_state; hostmachine = $localhost; elapsed_ms=$out.elapsed_ms;app_isAlive_elapsed_ms=$out.app_isAlive_elapsed_ms  }
            }
            else {
                Write-Output "Publishing various IsAlive probe FAILURE metrics to Timeseries database"
                # we publish sql state down and read error counts here 
                Write-LogToJSON -Msg $out.Error -LogFile $FilePath -LogLevel "ERROR" -ExtraArgs @{Check = "IsAlive"; Result = $checkResult.Failure ; Name = $($MyInvocation.MyCommand.Name); sql_state = 0; hostmachine = $localhost; elapsed_ms=$out.elapsed_ms;app_isAlive_elapsed_ms=$out.app_isAlive_elapsed_ms }
            }


            ## Write - IsReady Probe ... 

            $writeOut = Invoke-DbHealthProbeIsReady -listener $listener

            if ($writeOut.ExitCode -eq 1) {
                Write-Output "Publishing various IsReady Probe SUCCESS metrics to Timeseries database"
                 # log to log file as well
                $writemsg = "Performed successful IsReady Probe - WRITE and published metrics to Timeseries database"
                Write-LogToJSON -Msg $writemsg -LogFile $FilePath -LogLevel "INFO" -ExtraArgs @{Check = "IsReady" ; Result = $checkResult.Success; Name = $($MyInvocation.MyCommand.Name); sql_state = $writeOut.sql_state; hostmachine = $localhost; inserted_ms=$writeOut.inserted_ms;app_isReady_elapsed_ms=$writeOut.app_isReady_elapsed_ms }
            }
            else {

                Write-Output "Publishing various IsReady probe FAILURE metrics to Timeseries database"
                # we publish sql state down and read error counts here         
                Write-LogToJSON -Msg $WriteOut.Error -LogFile $FilePath -LogLevel "ERROR" -ExtraArgs @{Check = "IsReady"; Result = $checkResult.Failure ; Name = $($MyInvocation.MyCommand.Name); sql_state = 0; hostmachine = $localhost; inserted_ms=$writeOut.inserted_ms;app_isReady_elapsed_ms=$writeOut.app_isReady_elapsed_ms  }
            }          
        }
        else {
            # This is total connection failure .. so we treat this a db unavailability .. READ failures. So there is no point in publishing WRITE metrics 
            Write-LogToJSON -Msg $connError -LogFile $FilePath -LogLevel "ERROR" -ExtraArgs @{Check = "IsAlive"; Result = $checkResult.Failure ; Name = $($MyInvocation.MyCommand.Name); sql_state = 0; hostmachine = $localhost }
   
        }

        # sleep for some time
        Start-Sleep -Seconds $sleepTime 
    
    }
  
}
