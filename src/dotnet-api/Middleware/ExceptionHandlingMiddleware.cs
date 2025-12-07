using System.Net;
using System.Text.Json;

namespace AzureInfrastructureApi.Middleware;

/// <summary>
/// Global exception handling middleware
/// </summary>
public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;
    private readonly IHostEnvironment _environment;

    public ExceptionHandlingMiddleware(
        RequestDelegate next,
        ILogger<ExceptionHandlingMiddleware> logger,
        IHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        _logger.LogError(exception, "An unhandled exception occurred: {Message}", exception.Message);

        var statusCode = exception switch
        {
            ArgumentException => HttpStatusCode.BadRequest,
            KeyNotFoundException => HttpStatusCode.NotFound,
            UnauthorizedAccessException => HttpStatusCode.Unauthorized,
            InvalidOperationException => HttpStatusCode.Conflict,
            TimeoutException => HttpStatusCode.GatewayTimeout,
            _ => HttpStatusCode.InternalServerError
        };

        var response = new ErrorResponse
        {
            Error = GetErrorType(statusCode),
            Message = GetMessage(exception, statusCode),
            TraceId = context.TraceIdentifier,
            Timestamp = DateTime.UtcNow
        };

        // Include stack trace in development
        if (_environment.IsDevelopment())
        {
            response.Details = exception.ToString();
        }

        context.Response.StatusCode = (int)statusCode;
        context.Response.ContentType = "application/json";

        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        await context.Response.WriteAsync(JsonSerializer.Serialize(response, options));
    }

    private static string GetErrorType(HttpStatusCode statusCode) => statusCode switch
    {
        HttpStatusCode.BadRequest => "bad_request",
        HttpStatusCode.NotFound => "not_found",
        HttpStatusCode.Unauthorized => "unauthorized",
        HttpStatusCode.Forbidden => "forbidden",
        HttpStatusCode.Conflict => "conflict",
        HttpStatusCode.GatewayTimeout => "timeout",
        _ => "internal_error"
    };

    private string GetMessage(Exception exception, HttpStatusCode statusCode)
    {
        if (statusCode == HttpStatusCode.InternalServerError && !_environment.IsDevelopment())
        {
            return "An unexpected error occurred. Please try again later.";
        }

        return exception.Message;
    }
}

public class ErrorResponse
{
    public string Error { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string TraceId { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
    public string? Details { get; set; }
}
