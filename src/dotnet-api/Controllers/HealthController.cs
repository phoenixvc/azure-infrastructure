using Microsoft.AspNetCore.Mvc;

namespace AzureInfrastructureApi.Controllers;

/// <summary>
/// Health check endpoints for Azure probes
/// </summary>
[ApiController]
[Route("[controller]")]
public class HealthController : ControllerBase
{
    private readonly ILogger<HealthController> _logger;

    public HealthController(ILogger<HealthController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Liveness probe - is the app running?
    /// </summary>
    [HttpGet("live")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public IActionResult GetLive()
    {
        return Ok(new { Status = "Healthy", Timestamp = DateTime.UtcNow });
    }

    /// <summary>
    /// Readiness probe - is the app ready to receive traffic?
    /// </summary>
    [HttpGet("ready")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public IActionResult GetReady()
    {
        // Add dependency checks here if needed
        return Ok(new { Status = "Ready", Timestamp = DateTime.UtcNow });
    }

    /// <summary>
    /// Startup probe - has the app finished starting?
    /// </summary>
    [HttpGet("startup")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public IActionResult GetStartup()
    {
        return Ok(new { Status = "Started", Timestamp = DateTime.UtcNow });
    }
}
