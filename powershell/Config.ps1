# database name that is part of Availability Group
$global:databaseName = "YourDBNameGoesHere"

# local host info     
$global:localhost = $env:COMPUTERNAME

# we have created this as SPs in database  
$global:testReadStoredProc = "dbo.usp_dbHealthCheckSelect"

# The table dbo.sql_health_check is created with primary key as NONCLUSTERED to prevent last key contention problem. 
$global:testWriteStoredProc = "dbo.usp_dbHealthCheckSelectWrite"

# sleep time  seconds ;  
$global:sleepTime = 5

#  read failure count to be publish as counter in Timeseries database 
$global:readFailure = 1

#  write failure count to be publish as counter in Timeseries database 
$global:writeFailure = 1

# check results
$global:checkResult = @{Success = "SUCCESS"; Failure = "FAILURE" }

# Specifies the number of seconds before the query timesout.
$global:queryTimeout = 10   

# The length of time (in seconds) to wait for a connection to the server before terminating the attempt and generating an error.     
$global:connectionTimeout = 10  

# Failure Default value to publish
$global:defaultFailureMetric = -1
