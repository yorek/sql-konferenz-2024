/*
	Cleanup if needed
*/
if not exists(select * from sys.symmetric_keys where [name] = '##MS_DatabaseMasterKey##')
begin
	create master key encryption by password = 'Pa$$w0rd!'
end
go
if exists(select * from sys.[external_data_sources] where name = 'sqlkonferenz2024')
begin
	drop external data source [sqlkonferenz2024];
end
go
if exists(select * from sys.[database_scoped_credentials] where name = 'sqlkonferenz2024')
begin
	drop database scoped credential [sqlkonferenz2024];
end
go





