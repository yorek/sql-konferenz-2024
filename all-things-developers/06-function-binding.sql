alter database current 
set change_tracking = on  
(change_retention = 2 days, auto_cleanup = on)  
go

alter table [dbo].[sessions] 
enable change_tracking with (track_columns_updated = off);
go

select * from dbo.sessions
go

insert into dbo.sessions 
    (session_id, title, [description], details)
values
    (999999, N'Azure SQL ❤️ AI', N'Azure SQL loves AI and it empower developers with fantastic feature to build super cool AI solutions!', '{"owner":["Davide Mauri"], "language": "English", "track": "Developers"}')
go

delete from dbo.sessions where session_id = 999999;
go

