using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices(services => {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();        
        services.AddMvcCore()            
            .AddJsonOptions(options => {
                options.JsonSerializerOptions.IncludeFields = true;                
            })
            .AddXmlSerializerFormatters();
    })
    .Build();

host.Run();
