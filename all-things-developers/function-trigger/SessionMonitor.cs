using System;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Azure.Functions.Worker.Extensions.Sql;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Microsoft.Azure
{
    public class SessionMonitor(ILoggerFactory loggerFactory)
    {
        private readonly ILogger _logger = loggerFactory.CreateLogger<SessionMonitor>();

        // Visit https://aka.ms/sqltrigger to learn how to use this trigger binding
        [Function("SessionMonitor")]
        public void Run(
            [SqlTrigger("[dbo].[sessions]", "MSSQL")] IReadOnlyList<SqlChange<SessionItem>> changes,
            FunctionContext context)
        {
            _logger.LogInformation("SQL Changes: " + JsonSerializer.Serialize(changes));
        }
    }

    public class SessionItem
    {
        [JsonPropertyName("session_id")]
        public int? SessionId { get; set; }
        public string? Title { get; set; }
        public string? Description { get; set; }
    }
}
