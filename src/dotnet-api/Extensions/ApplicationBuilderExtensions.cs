using AspNetCoreRateLimit;

namespace AzureInfrastructureApi.Extensions;

/// <summary>
/// Application builder extension methods
/// </summary>
public static class ApplicationBuilderExtensions
{
    public static IApplicationBuilder UseRateLimiting(this IApplicationBuilder app)
    {
        app.UseIpRateLimiting();
        return app;
    }
}
