create procedure [dbo].[usp_dbHealthCheckSelectWrite] (@servername varchar(30))
as

/*
BEGINSAMPLE
    exec dbo.usp_dbHealthCheckSelectWrite @servername = 'someservername'
ENDSAMPLE
*/

    set nocount on
	-- the check is very lightweight
	-- to avoid blocking ..
    set LOCK_TIMEOUT 500;
    SELECT @@SERVERNAME as primary_server;

    declare @start datetime2(7) = getdate()
    insert into [dbo].[sql_health_check] (applicationServerName) values(@servername)
    declare @end datetime2(7) = getdate()
    select datediff(millisecond,@start,@end) as inserted_ms
RETURN
GO
----  change here to you application_user !!
grant execute on dbo.usp_dbHealthCheckSelectWrite to [application_user]
go
