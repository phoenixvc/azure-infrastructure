using AzureInfrastructureApi.Extensions;
using AzureInfrastructureApi.Middleware;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new()
    {
        Title = "Azure Infrastructure API",
        Version = "v1",
        Description = "A .NET reference implementation for Azure deployments"
    });
});

// Add custom services
builder.Services.AddApplicationServices(builder.Configuration);
builder.Services.AddDatabaseServices(builder.Configuration);
builder.Services.AddCachingServices(builder.Configuration);
builder.Services.AddMessagingServices(builder.Configuration);
builder.Services.AddStorageServices(builder.Configuration);
builder.Services.AddResilienceServices();
builder.Services.AddObservabilityServices(builder.Configuration);
builder.Services.AddRateLimiting(builder.Configuration);
builder.Services.AddHealthChecks(builder.Configuration);

var app = builder.Build();

// Configure pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseRateLimiting();
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseAuthorization();
app.MapControllers();
app.MapHealthChecks("/health");

// Root endpoint
app.MapGet("/", () => new
{
    Name = "Azure Infrastructure API",
    Version = "1.0.0",
    Docs = "/swagger",
    Health = "/health",
    Api = "/api/v1"
});

app.Run();

// For integration tests
public partial class Program { }
