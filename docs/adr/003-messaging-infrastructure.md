# ADR-003: Messaging Infrastructure

## Status

Accepted

## Date

2025-12-07

## Context

The application requires asynchronous messaging capabilities for:
- Decoupling services for better scalability
- Handling background job processing
- Event-driven architecture patterns
- Reliable message delivery with at-least-once semantics

We need a messaging service that supports both point-to-point (queues) and publish-subscribe (topics) patterns.

## Decision Drivers

- **Reliability**: Guaranteed message delivery with dead-letter support
- **Scalability**: Handle high throughput with horizontal scaling
- **Patterns**: Support for queues, topics, and subscriptions
- **Integration**: Native Azure integration and SDK support
- **Cost**: Appropriate pricing for message volume

## Considered Options

1. **Azure Service Bus**
2. **Azure Event Hubs**
3. **Azure Event Grid**
4. **Azure Storage Queues**
5. **RabbitMQ on Azure VMs**

## Evaluation Matrix

| Criterion | Weight | Service Bus | Event Hubs | Event Grid | Storage Queues | RabbitMQ |
|-----------|--------|-------------|------------|------------|----------------|----------|
| Message Ordering | 4 | 5 (20) | 4 (16) | 2 (8) | 3 (12) | 5 (20) |
| Pub/Sub Support | 5 | 5 (25) | 5 (25) | 5 (25) | 1 (5) | 5 (25) |
| Dead Letter Handling | 5 | 5 (25) | 3 (15) | 3 (15) | 2 (10) | 5 (25) |
| Azure Integration | 4 | 5 (20) | 5 (20) | 5 (20) | 5 (20) | 2 (8) |
| Transaction Support | 4 | 5 (20) | 2 (8) | 1 (4) | 1 (4) | 4 (16) |
| Cost at Low Volume | 3 | 3 (9) | 2 (6) | 4 (12) | 5 (15) | 2 (6) |
| Cost at High Volume | 3 | 4 (12) | 5 (15) | 3 (9) | 4 (12) | 3 (9) |
| Operational Simplicity | 4 | 5 (20) | 5 (20) | 5 (20) | 5 (20) | 2 (8) |
| **Total** | **32** | **151** | **125** | **113** | **98** | **117** |

### Scoring Guide
- **Weight**: 1 (Nice to have) → 5 (Critical)
- **Score**: 1 (Poor) → 5 (Excellent)

## Decision

**Azure Service Bus** as primary messaging infrastructure.

Use **Event Grid** as a complement for event-driven webhooks and Azure service events.

## Rationale

Azure Service Bus scored highest due to:

1. **Enterprise messaging features**: FIFO ordering, sessions, transactions, and scheduled delivery.

2. **Robust dead-letter handling**: Automatic DLQ with inspection and replay capabilities.

3. **Flexible patterns**: Supports both queues (point-to-point) and topics with subscriptions (pub-sub).

4. **Message sessions**: Enables stateful processing and ordered delivery per session.

5. **Large message support**: Up to 100MB in Premium tier (vs 64KB for Storage Queues).

### When to Use Each Service

| Use Case | Service |
|----------|---------|
| Command processing, task queues | Service Bus Queue |
| Event broadcasting to multiple subscribers | Service Bus Topic |
| Azure-to-Azure event routing | Event Grid |
| High-throughput streaming | Event Hubs |
| Simple, low-cost queuing | Storage Queues |

## Consequences

### Positive

- Guaranteed message delivery with duplicate detection
- Built-in retry policies and dead-letter queues
- Session support for ordered processing
- Auto-forwarding for message routing
- Scheduled message delivery

### Negative

- Higher cost than Storage Queues for simple scenarios
- Requires understanding of messaging concepts
- Premium tier needed for VNet integration
- Message size limits (256KB Standard, 100MB Premium)

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Message loss | Low | High | Enable duplicate detection, use transactions |
| Poison messages | Medium | Medium | Implement DLQ monitoring and alerting |
| Throughput limits | Low | Medium | Use partitioning, Premium tier for high scale |
| Cost overrun | Medium | Low | Monitor message counts, optimize batch size |

## Abstraction Requirements

Implement a messaging abstraction layer to enable:
- Swapping between Service Bus and in-memory implementations
- Easier testing with mock message brokers
- Consistent API across the application

See `src/api/app/messaging/base.py` for the messaging abstraction interface.

## References

- [Azure Service Bus](https://docs.microsoft.com/azure/service-bus-messaging/)
- [Service Bus vs Event Hubs vs Event Grid](https://docs.microsoft.com/azure/event-grid/compare-messaging-services)
- [Messaging Patterns](https://docs.microsoft.com/azure/architecture/patterns/category/messaging)
