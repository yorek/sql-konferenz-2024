/*
	Create database scoped credential and external data source.
	File is assumed to be in a path like: 
	https://<myaccount>.blob.core.windows.net/playground/wikipedia/vector_database_wikipedia_articles_embedded.csv

	Please note that it is recommened to avoid using SAS tokens: the best practice is to use Managed Identity as described here:
	https://learn.microsoft.com/en-us/sql/relational-databases/import-export/import-bulk-data-by-using-bulk-insert-or-openrowset-bulk-sql-server?view=sql-server-ver16#bulk-importing-from-azure-blob-storage
*/
create database scoped credential [sqlkonferenz2024]
with identity = 'Managed Identity'
go
create external data source [sqlkonferenz2024]
with 
( 
	type = blob_storage,
 	location = 'https://dmsqlkonferenz2024.blob.core.windows.net/demo',
 	credential = [sqlkonferenz2024]
);
go

--  Load JSON from blob (make sure JSON is using character escaping to avoid issues with Unicode characters)
declare @s json;
select top(1) 
    @s = cast(BulkColumn as json) 
from 
    openrowset(bulk 'sessions.json', single_clob, data_source = 'sqlkonferenz2024', codepage='65001') r;

/*

Coming for GA

declare @s json;
select top(1) 
    @s = BulkColumn
from 
    openrowset(bulk 'sessions.json', single_clob, format='json', data_source = 'sqlkonferenz2024', codepage='65001') r;
*/

-- Store into a temp table
drop table if exists dbo.sessions;
select 
    * 
into 
    dbo.sessions
from 
    openjson(cast(@s as nvarchar(max))) -- Once GA cast will not be needed anymore
        with (
            session_id int '$.sessionId',
            title nvarchar(100),
            [description] nvarchar(max),
            details nvarchar(max) as json -- Once GA you can just say JSON column
        );
go

alter table dbo.sessions
alter column [session_id] int not null
go

alter table dbo.sessions
add constraint pk__sessions primary key(session_id)
go

alter table dbo.sessions
alter column [details] json not null
go

select * from dbo.sessions


update dbo.sessions 
set title ||= unistr(N' - \2764') -- some delighters for strings
where session_id = 683984
go

select * from dbo.sessions where session_id = 683984
go

alter table dbo.sessions  
add imported_by sysname not null default (system_user)
go

alter table dbo.sessions 
add imported_on date not null default (current_date) -- get current *date* only! :)
go

select * from dbo.sessions
go

select 
    json_object(
        title: json_object(
            'id': session_id,
            'speaker': json_value(details, '$.owner[0]')
        )        
    ),
    *
from
    dbo.sessions
go

alter table dbo.sessions
add [language] as json_value(details, '$.language') persisted
go

alter table dbo.sessions
add [level] as cast(json_value(details, '$.level') as int) persisted
go

select * from dbo.sessions where title like 'Taming%'
go

update 
    dbo.sessions
set
    details = json_modify(details, '$.language', 'English')
where
    title like 'Taming%'
go

select * from dbo.sessions where title like 'Taming%'
go

select 
    [language],
    json_arrayagg(
        json_object(
            title: json_object(
                'id': session_id,
                'speaker': json_value(details, '$.owner[0]')
            )        
        )
    )
from
    dbo.sessions
group by
    [language]

select     
    json_object(
        [language]: json_query(json_objectagg( -- For now, will be fixed ASAP
            title: json_object(
                'id': session_id,
                'speaker': json_value(details, '$.owner[0]')
            )        
        ))
    )
from
    dbo.sessions
group by
    [language]

select     
    json_object(
        [language]: json_query(json_arrayagg( -- For now, will be fixed ASAP
            json_object(
                'title': title,
                'id': session_id,
                'speaker': json_value(details, '$.owner[0]')
            ))        
        )
    )
from
    dbo.sessions
group by
    [language]

-- Json Aggregate Support for Grouping Sets and Windowing Functions are coming for GA



 
    
