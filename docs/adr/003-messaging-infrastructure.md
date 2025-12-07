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

## Multi-Language SDK Support

| Language | Service Bus Client | Async Support | Batch Processing |
|----------|-------------------|---------------|------------------|
| Python | azure-servicebus | Native async | Yes |
| .NET | Azure.Messaging.ServiceBus | Native async | Yes |
| Node.js | @azure/service-bus | Promises/async | Yes |
| Go | azservicebus | Context-based | Yes |
| Java | azure-messaging-servicebus | Reactive | Yes |

## Cost Estimation

### Azure Service Bus Pricing

| Tier | Base Cost | Per Million Messages | Max Message Size |
|------|-----------|---------------------|------------------|
| Basic | ~$0.05/hr | $0.05 | 256 KB |
| Standard | ~$10/month | $0.80 (first 13M free) | 256 KB |
| Premium (1 MU) | ~$700/month | Included | 100 MB |

### Monthly Cost Examples

| Workload | Tier | Messages/Month | Est. Monthly Cost |
|----------|------|----------------|-------------------|
| Dev/test | Basic | 100K | ~$5 |
| Small app | Standard | 5M | ~$15 |
| Medium app | Standard | 50M | ~$45 |
| Enterprise | Premium 1MU | Unlimited* | ~$700 |

*Premium includes unlimited operations within capacity

### Cost Optimization Strategies

| Strategy | Savings | Trade-off |
|----------|---------|-----------|
| Batch messages | 50-80% | Increased latency |
| Use sessions wisely | Indirect | Session limits |
| Right-size Premium MUs | 30-50% | Capacity planning |
| Use Storage Queues for simple needs | 90% | Limited features |

## Multi-Cloud Alternatives

| Cloud | Managed Message Queue | Key Differences |
|-------|----------------------|-----------------|
| Azure | Service Bus | Best enterprise features |
| AWS | SQS + SNS | Simpler, cheaper |
| GCP | Pub/Sub | Global by default |
| Self-hosted | RabbitMQ / Kafka | Full control |

### Terraform Multi-Cloud

| Provider | Resource Type |
|----------|---------------|
| Azure | `azurerm_servicebus_namespace` |
| AWS | `aws_sqs_queue` + `aws_sns_topic` |
| GCP | `google_pubsub_topic` |

### Cloud-Agnostic Alternatives

| Alternative | Best For | Trade-off |
|-------------|----------|-----------|
| Apache Kafka | High-throughput streaming | Operational complexity |
| RabbitMQ | Flexible routing | Self-managed |
| NATS | Low-latency, lightweight | Fewer enterprise features |
| Apache Pulsar | Multi-tenancy | Newer, smaller community |

## Distributed Patterns

### Saga Pattern (Choreography)

| Step | Description | Compensation |
|------|-------------|--------------|
| 1 | Order created → Publish OrderCreated | Cancel order |
| 2 | Inventory reserved → Publish InventoryReserved | Release inventory |
| 3 | Payment processed → Publish PaymentCompleted | Refund payment |
| 4 | Order confirmed | N/A (success) |

### Saga Pattern (Orchestration)

| Component | Responsibility |
|-----------|----------------|
| Saga Orchestrator | Coordinates all steps |
| Step Executors | Perform individual actions |
| Compensation Handlers | Rollback on failure |
| State Store | Track saga progress |

### Retry and Circuit Breaker

| Pattern | Use Case | Configuration |
|---------|----------|---------------|
| Immediate retry | Transient failures | 3 attempts, no delay |
| Exponential backoff | Rate limiting | 1s, 2s, 4s, 8s |
| Circuit breaker | Prevent cascade | Open after 5 failures |
| Dead letter | Poison messages | After max retries |

### Event Sourcing Considerations

| Aspect | Recommendation |
|--------|----------------|
| Event Store | Service Bus + Blob Storage or Event Hubs |
| Projections | Separate read models |
| Snapshots | Periodic state capture |
| Replay | Support event replay for new projections |

## High Availability & Disaster Recovery

### HA Configurations

| Configuration | RTO | RPO | Cost Impact |
|---------------|-----|-----|-------------|
| Standard (single region) | Hours | Near zero | Baseline |
| Premium (zone redundant) | Minutes | Near zero | +100% |
| Geo-DR (paired regions) | Minutes | Minutes | +100% |

### Geo-Disaster Recovery

| Scenario | Action | Data Impact |
|----------|--------|-------------|
| Primary failure | Manual failover to secondary | Possible message loss |
| Planned failover | Sync then switch | No data loss |
| Recovery | Fail back when primary ready | Resync required |

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
