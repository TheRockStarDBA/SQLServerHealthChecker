create procedure [dbo].[usp_dbHealthCheckSelect]
as

/*
BEGINSAMPLE
    exec dbo.usp_dbHealthCheckSelect
ENDSAMPLE
*/
    set nocount on
    set LOCK_TIMEOUT 250;
    declare @t1 datetime2(7) = getdate();
    -- we will get the pimary server name part of select here. 
    -- this will confirm that the instance is accessible
    SELECT @@SERVERNAME as primary_server;
    declare @t2 datetime2(7) = getdate();
    select datediff(millisecond, @t1,@t2) as elapsed_ms;
RETURN

GO
-- Change here ! grant permissions to application_user
grant execute on dbo.usp_dbHealthCheckSelect to [application_user]
go
