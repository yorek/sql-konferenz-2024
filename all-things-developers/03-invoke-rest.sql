declare @url nvarchar(1000) = 'https://dm-sql-konferenz-2024-demo.azurewebsites.net/api/purchase-order?id=1'
declare @response nvarchar(max);
exec sp_invoke_external_rest_endpoint 
    @url = @url,
    @method = 'GET',
    @response = @response output
select @response;


declare @url nvarchar(1000) = 'https://dm-sql-konferenz-2024-demo.azurewebsites.net/api/purchase-order'
declare @payload nvarchar(max) = json_object('id':2)
declare @response nvarchar(max);
exec sp_invoke_external_rest_endpoint 
    @url = @url,
    @method = 'POST',
    @payload = @payload,
    @response = @response output
select cast(@response as json);


declare @url nvarchar(1000) = 'https://dm-sql-konferenz-2024-demo.azurewebsites.net/api/purchase-order'
declare @payload nvarchar(max) = json_object('id':2)
declare @response nvarchar(max);
exec sp_invoke_external_rest_endpoint 
    @url = @url,
    @headers = '{"Accept": "application/xml"}',
    @method = 'POST',
    @payload = @payload,
    @response = @response output
select cast(@response as xml);

drop  database scoped credential [https://dmsqlkonferenz2024.blob.core.windows.net]
create database scoped credential [https://dmsqlkonferenz2024.blob.core.windows.net]
with identity = 'Managed Identity', secret = '{"resourceid": "https://dmsqlkonferenz2024.blob.core.windows.net" }';
go

declare @ret int, @response nvarchar(max);
declare @headers nvarchar(1000) = json_object(
        'Accept':'application/json',
        'x-ms-version': '2023-08-03');
exec @ret = sp_invoke_external_rest_endpoint
  @url = N'https://dmsqlkonferenz2024.blob.core.windows.net/demo/sessions.json',
  @headers = @headers,
  @credential = [https://dmsqlkonferenz2024.blob.core.windows.net],
  @method = 'GET',
  @response = @response OUTPUT;

select @response;

-- Create a file
declare @response nvarchar(max);
declare @url nvarchar(max) = 'https://dmsqlkonferenz2024.blob.core.windows.net/demo/test-me-from-azure-sql.json'
declare @payload nvarchar(max) = (select * from (values('Hello from Azure SQL!', sysdatetime())) payload([message], [timestamp]) for json auto, without_array_wrapper)
declare @len int = len(@payload)
declare @headers nvarchar(max) = json_object(
        'Accept':'application/json',
        'x-ms-version': '2023-08-03',
        'x-ms-blob-type': 'BlockBlob',
        'Content-Length': cast(@len as varchar(9)))

exec sp_invoke_external_rest_endpoint
    @url = @url,
    @method = 'PUT',
    @headers = @headers,
    @payload = @payload,
    @credential = [https://dmsqlkonferenz2024.blob.core.windows.net],
    @response = @response output
select cast(@response as json);
go
