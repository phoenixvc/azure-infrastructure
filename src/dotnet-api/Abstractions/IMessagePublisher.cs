namespace AzureInfrastructureApi.Abstractions;

/// <summary>
/// Message publisher interface for messaging abstraction
/// Enables swapping between Service Bus, RabbitMQ, or in-memory
/// </summary>
public interface IMessagePublisher
{
    Task PublishAsync<T>(
        string topic,
        T message,
        IDictionary<string, object>? properties = null,
        CancellationToken cancellationToken = default);

    Task PublishAsync<T>(
        string topic,
        IEnumerable<T> messages,
        CancellationToken cancellationToken = default);

    Task ScheduleAsync<T>(
        string topic,
        T message,
        DateTimeOffset scheduledTime,
        CancellationToken cancellationToken = default);
}

/// <summary>
/// Message consumer interface for receiving messages
/// </summary>
public interface IMessageConsumer
{
    Task StartAsync(CancellationToken cancellationToken = default);
    Task StopAsync(CancellationToken cancellationToken = default);
}

/// <summary>
/// Message handler interface
/// </summary>
public interface IMessageHandler<T>
{
    Task HandleAsync(T message, CancellationToken cancellationToken = default);
}
