using System.Collections.Concurrent;
using AzureInfrastructureApi.Abstractions;
using Microsoft.Extensions.Logging;

namespace AzureInfrastructureApi.Services;

/// <summary>
/// In-memory message publisher for development and testing
/// </summary>
public class InMemoryMessagePublisher : IMessagePublisher
{
    private readonly ILogger<InMemoryMessagePublisher> _logger;
    private readonly ConcurrentDictionary<string, ConcurrentQueue<object>> _topics = new();

    public InMemoryMessagePublisher(ILogger<InMemoryMessagePublisher> logger)
    {
        _logger = logger;
    }

    public Task PublishAsync<T>(
        string topic,
        T message,
        IDictionary<string, object>? properties = null,
        CancellationToken cancellationToken = default)
    {
        var queue = _topics.GetOrAdd(topic, _ => new ConcurrentQueue<object>());
        queue.Enqueue(message!);

        _logger.LogInformation("Published message to topic {Topic}: {Message}", topic, message);
        return Task.CompletedTask;
    }

    public Task PublishAsync<T>(
        string topic,
        IEnumerable<T> messages,
        CancellationToken cancellationToken = default)
    {
        var queue = _topics.GetOrAdd(topic, _ => new ConcurrentQueue<object>());

        foreach (var message in messages)
        {
            queue.Enqueue(message!);
        }

        _logger.LogInformation("Published {Count} messages to topic {Topic}",
            messages.Count(), topic);
        return Task.CompletedTask;
    }

    public Task ScheduleAsync<T>(
        string topic,
        T message,
        DateTimeOffset scheduledTime,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation(
            "Scheduled message for topic {Topic} at {ScheduledTime}: {Message}",
            topic, scheduledTime, message);

        // In-memory implementation doesn't actually schedule
        return PublishAsync(topic, message, null, cancellationToken);
    }

    /// <summary>
    /// Get messages from a topic (for testing)
    /// </summary>
    public IEnumerable<T> GetMessages<T>(string topic)
    {
        if (_topics.TryGetValue(topic, out var queue))
        {
            return queue.Cast<T>().ToList();
        }

        return Enumerable.Empty<T>();
    }

    /// <summary>
    /// Clear all messages (for testing)
    /// </summary>
    public void Clear()
    {
        _topics.Clear();
    }
}
