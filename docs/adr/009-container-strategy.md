# ADR-009: Container & Compute Strategy

## Status

Accepted

## Date

2025-12-07

## Context

The platform needs to run containerized workloads with:
- Automatic scaling based on demand
- High availability and fault tolerance
- Cost optimization for variable workloads
- Support for both APIs and background jobs
- Integration with CI/CD pipelines

We need a container hosting strategy that balances operational simplicity, cost, and capability.

## Decision Drivers

- **Operational Complexity**: Team skill requirements
- **Scalability**: Auto-scaling capabilities
- **Cost**: Pricing model for our workload patterns
- **Features**: Ingress, secrets, networking
- **Portability**: Kubernetes compatibility

## Considered Options

1. **Azure App Service (Web Apps + Containers)**
2. **Azure Kubernetes Service (AKS)**
3. **Azure Container Apps (ACA)**
4. **Azure Container Instances (ACI)**
5. **Azure Functions (Containerized)**

## Evaluation Matrix

| Criterion | Weight | App Service | AKS | Container Apps | ACI | Functions |
|-----------|--------|-------------|-----|----------------|-----|-----------|
| Operational Simplicity | 5 | 5 (25) | 2 (10) | 4 (20) | 5 (25) | 5 (25) |
| Auto-scaling | 5 | 4 (20) | 5 (25) | 5 (25) | 2 (10) | 5 (25) |
| Cost Efficiency | 4 | 3 (12) | 3 (12) | 4 (16) | 5 (20) | 4 (16) |
| K8s Compatibility | 3 | 1 (3) | 5 (15) | 4 (12) | 3 (9) | 1 (3) |
| Networking | 4 | 4 (16) | 5 (20) | 4 (16) | 3 (12) | 3 (12) |
| Secrets Management | 4 | 4 (16) | 5 (20) | 4 (16) | 3 (12) | 4 (16) |
| Microservices Support | 4 | 3 (12) | 5 (20) | 5 (20) | 2 (8) | 3 (12) |
| Background Jobs | 4 | 3 (12) | 5 (20) | 5 (20) | 4 (16) | 5 (20) |
| **Total** | **33** | **116** | **142** | **145** | **112** | **129** |

## Decision

**Azure Container Apps (ACA)** as the primary compute platform with:

| Workload | Platform | Rationale |
|----------|----------|-----------|
| APIs/Web Apps | Container Apps | Scale to zero, KEDA scaling |
| Background Jobs | Container Apps Jobs | Event-driven execution |
| Scheduled Tasks | Container Apps Jobs | Cron-based scheduling |
| Legacy Apps | App Service | Easier migration path |
| Complex Orchestration | AKS | When full K8s needed |

## Rationale

Azure Container Apps scored highest due to:

1. **Serverless containers**: Scale to zero with per-second billing, ideal for variable workloads.

2. **Built-in KEDA**: Event-driven auto-scaling for queues, HTTP, custom metrics.

3. **Managed Dapr**: Sidecar support for service discovery, pub/sub, state management.

4. **Simplified networking**: Built-in ingress, traffic splitting, easy VNet integration.

5. **Kubernetes foundation**: Uses K8s under the hood without the management overhead.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                Container Apps Environment                        │
│                    (Managed Kubernetes)                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   API Service   │  │  Worker Service │  │  Job (Cron)     │  │
│  │   ───────────   │  │  ─────────────  │  │  ───────────    │  │
│  │   Replicas: 1-10│  │  Replicas: 1-5  │  │  Schedule: 0 *  │  │
│  │   HTTP Scaling  │  │  Queue Scaling  │  │  * * *          │  │
│  └────────┬────────┘  └────────┬────────┘  └─────────────────┘  │
│           │                    │                                 │
│  ┌────────┴────────────────────┴────────┐                       │
│  │            Dapr Sidecars             │                       │
│  │  (Service Discovery, Pub/Sub, State) │                       │
│  └──────────────────────────────────────┘                       │
│                                                                  │
│  ┌──────────────────────────────────────┐                       │
│  │         Internal Ingress             │                       │
│  │      (Service-to-Service)            │                       │
│  └──────────────────────────────────────┘                       │
│                                                                  │
└───────────────────────┬─────────────────────────────────────────┘
                        │
            ┌───────────┴───────────┐
            │    External Ingress   │
            │   (HTTPS, Custom DNS) │
            └───────────────────────┘
```

## Implementation

### Container App Configuration

| Configuration | Description |
|---------------|-------------|
| Revision mode | Multiple revisions for traffic splitting |
| Ingress | External with custom DNS support |
| Secrets | Key Vault references via managed identity |
| Registry | ACR with managed identity authentication |
| Health probes | Liveness and readiness endpoints |

### Scaling Options

| Scaling Type | Trigger | Use Case |
|--------------|---------|----------|
| HTTP | Concurrent requests | API workloads |
| KEDA (Queue) | Message count | Background processors |
| KEDA (Custom) | Custom metrics | Specialized workloads |
| Schedule | Cron expression | Jobs and maintenance |

### Resource Sizing

| Workload | CPU | Memory | Min Replicas | Max Replicas |
|----------|-----|--------|--------------|--------------|
| Light API | 0.25 | 0.5Gi | 0 | 5 |
| Standard API | 0.5 | 1Gi | 1 | 10 |
| Heavy Processing | 1.0 | 2Gi | 1 | 20 |
| Background Job | 0.25 | 0.5Gi | 0 | 10 |

## When to Use Each Platform

| Scenario | Platform | Reason |
|----------|----------|--------|
| REST APIs | Container Apps | HTTP scaling, scale to zero |
| Event processors | Container Apps | KEDA scaling, queue triggers |
| Scheduled jobs | Container Apps Jobs | Cron support, one-time execution |
| Complex microservices | AKS | Full K8s control |
| Legacy .NET apps | App Service | Simpler migration |
| Burst compute | ACI | Quick spin-up, no cluster |

## Consequences

### Positive

- Minimal infrastructure management
- Scale to zero reduces costs
- Built-in Dapr for microservices patterns
- Easy revision management and traffic splitting
- Integrated with Azure services

### Negative

- Less control than raw Kubernetes
- Some AKS features not available
- Cold start latency on scale from zero
- Regional availability limited

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Cold start latency | Medium | Medium | Keep minReplicas=1 for critical paths |
| Resource limits | Low | Medium | Monitor usage, request increases |
| Feature gaps vs AKS | Medium | Low | Use AKS for complex needs |

## References

- [Azure Container Apps](https://docs.microsoft.com/azure/container-apps/)
- [KEDA Scalers](https://keda.sh/docs/scalers/)
- [Dapr on Container Apps](https://docs.microsoft.com/azure/container-apps/dapr-overview)
