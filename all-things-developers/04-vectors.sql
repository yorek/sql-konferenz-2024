declare @v1 vector(3) = cast('[1,3,-5]' as vector(3))
declare @v2 vector(3) = cast('[4,-2,-1]' as vector(3))
select
    vector_distance('euclidean', @v1, @v2) as euclidean_distance,
    vector_distance('cosine', @v1, @v2) as cosine_distance,
    vector_distance('dot', @v1, @v2) as negative_dotproduct_distance
go

-- show already calculated embeddings for sessions
select *, cast(details_vector_text3 as nvarchar(max)) from dbo.sessions_embeddings
go

declare @qv vector(1536)
exec dbo.get_embedding @inputText = 'I want to learn about the new features of Azure SQL ', @embedding = @qv output
drop table if exists #t;
select @qv as query_vector into #t
select cast(query_vector as varchar(max)) from #t
go

-- find the closest 5 sessions to the query vector
select top(5)
    s.session_id, 
    s.title,
    s.[description],
    s.level,
    vector_distance('cosine', se.details_vector_text3, t.query_vector) as distance_score 
from 
    dbo.sessions_embeddings se
cross join
    #t t
inner join 
    dbo.sessions s on s.session_id = se.session_id
and
    s.[language] = 'English'
and
    s.level <= 300
order by
    distance_score