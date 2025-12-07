using AzureInfrastructureApi.Abstractions;
using AzureInfrastructureApi.Models;
using AzureInfrastructureApi.Services;
using AspNetCoreRateLimit;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Polly;
using Polly.Extensions.Http;
using Polly.Timeout;

namespace AzureInfrastructureApi.Extensions;

/// <summary>
/// Service collection extension methods for clean DI setup
/// </summary>
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApplicationServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Add HTTP context accessor
        services.AddHttpContextAccessor();

        return services;
    }

    public static IServiceCollection AddDatabaseServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("Database");

        if (string.IsNullOrEmpty(connectionString))
        {
            // Use in-memory repository
            services.AddSingleton<IRepository<Item>>(sp =>
                new InMemoryRepository<Item>(item => item.Id));
        }
        else
        {
            // Add EF Core with PostgreSQL (implementation would go here)
            services.AddSingleton<IRepository<Item>>(sp =>
                new InMemoryRepository<Item>(item => item.Id));
        }

        return services;
    }

    public static IServiceCollection AddCachingServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var redisConnection = configuration.GetConnectionString("Redis");

        if (string.IsNullOrEmpty(redisConnection))
        {
            // Use in-memory cache
            services.AddSingleton<ICacheProvider, InMemoryCacheProvider>();
        }
        else
        {
            // Add Redis cache (implementation would go here)
            services.AddSingleton<ICacheProvider, InMemoryCacheProvider>();
        }

        return services;
    }

    public static IServiceCollection AddMessagingServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var serviceBusConnection = configuration["Azure:ServiceBusConnectionString"];

        if (string.IsNullOrEmpty(serviceBusConnection))
        {
            // Use in-memory messaging
            services.AddSingleton<IMessagePublisher, InMemoryMessagePublisher>();
        }
        else
        {
            // Add Service Bus (implementation would go here)
            services.AddSingleton<IMessagePublisher, InMemoryMessagePublisher>();
        }

        return services;
    }

    public static IServiceCollection AddStorageServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var storageConnection = configuration["Azure:StorageConnectionString"];

        if (string.IsNullOrEmpty(storageConnection))
        {
            // Use in-memory storage
            services.AddSingleton<IStorageProvider, InMemoryStorageProvider>();
        }
        else
        {
            // Add Azure Blob Storage (implementation would go here)
            services.AddSingleton<IStorageProvider, InMemoryStorageProvider>();
        }

        return services;
    }

    public static IServiceCollection AddResilienceServices(
        this IServiceCollection services)
    {
        // Configure Polly policies for HTTP clients
        services.AddHttpClient("ResilientClient")
            .AddPolicyHandler(GetRetryPolicy())
            .AddPolicyHandler(GetCircuitBreakerPolicy())
            .AddPolicyHandler(Policy.TimeoutAsync<HttpResponseMessage>(TimeSpan.FromSeconds(30)));

        return services;
    }

    public static IServiceCollection AddObservabilityServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var serviceName = "AzureInfrastructureApi";
        var serviceVersion = "1.0.0";

        services.AddOpenTelemetry()
            .ConfigureResource(resource => resource
                .AddService(serviceName, serviceVersion: serviceVersion))
            .WithTracing(tracing =>
            {
                tracing
                    .AddAspNetCoreInstrumentation()
                    .AddHttpClientInstrumentation()
                    .AddEntityFrameworkCoreInstrumentation();

                var appInsightsConnection = configuration["Azure:ApplicationInsightsConnectionString"];
                if (!string.IsNullOrEmpty(appInsightsConnection))
                {
                    tracing.AddAzureMonitorTraceExporter(options =>
                    {
                        options.ConnectionString = appInsightsConnection;
                    });
                }

                var otlpEndpoint = configuration["OpenTelemetry:OtlpEndpoint"];
                if (!string.IsNullOrEmpty(otlpEndpoint))
                {
                    tracing.AddOtlpExporter(options =>
                    {
                        options.Endpoint = new Uri(otlpEndpoint);
                    });
                }
            })
            .WithMetrics(metrics =>
            {
                metrics
                    .AddAspNetCoreInstrumentation()
                    .AddHttpClientInstrumentation();

                var appInsightsConnection = configuration["Azure:ApplicationInsightsConnectionString"];
                if (!string.IsNullOrEmpty(appInsightsConnection))
                {
                    metrics.AddAzureMonitorMetricExporter(options =>
                    {
                        options.ConnectionString = appInsightsConnection;
                    });
                }
            });

        return services;
    }

    public static IServiceCollection AddRateLimiting(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddMemoryCache();
        services.Configure<IpRateLimitOptions>(configuration.GetSection("RateLimiting"));
        services.AddInMemoryRateLimiting();
        services.AddSingleton<IRateLimitConfiguration, RateLimitConfiguration>();

        return services;
    }

    public static IServiceCollection AddHealthChecks(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var healthChecks = services.AddHealthChecks();

        var dbConnection = configuration.GetConnectionString("Database");
        if (!string.IsNullOrEmpty(dbConnection))
        {
            healthChecks.AddNpgSql(dbConnection, name: "postgresql");
        }

        var redisConnection = configuration.GetConnectionString("Redis");
        if (!string.IsNullOrEmpty(redisConnection))
        {
            healthChecks.AddRedis(redisConnection, name: "redis");
        }

        return services;
    }

    private static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy()
    {
        return HttpPolicyExtensions
            .HandleTransientHttpError()
            .Or<TimeoutRejectedException>()
            .WaitAndRetryAsync(
                retryCount: 3,
                sleepDurationProvider: retryAttempt =>
                    TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                onRetry: (outcome, timespan, retryAttempt, context) =>
                {
                    // Log retry attempt
                });
    }

    private static IAsyncPolicy<HttpResponseMessage> GetCircuitBreakerPolicy()
    {
        return HttpPolicyExtensions
            .HandleTransientHttpError()
            .CircuitBreakerAsync(
                handledEventsAllowedBeforeBreaking: 5,
                durationOfBreak: TimeSpan.FromSeconds(30));
    }
}
