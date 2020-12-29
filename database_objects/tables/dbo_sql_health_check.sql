   create table dbo.sql_health_check (
   id bigint identity(1,1) NOT NULL,
   insertDate datetime2(7) CONSTRAINT DF_insertDate Default (getdate()),
   applicationServerName varchar(50) NULL,
   -- primary key NONCLUSTERED index is created to avoid last key insert issue. 
   -- This is an append only table but N number of application servers will simultaneously write to it !
   PRIMARY KEY NONCLUSTERED (
   id ASC
   ) ON [PRIMARY]
   GO
   -- change here [application_user] as the actual user that you have
   GRANT SELECT on dbo.sql_health_check to [application_user]
